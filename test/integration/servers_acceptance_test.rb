require "test_helper"
require "json"
require "tmpdir"

class ServersAcceptanceTest < ActionDispatch::IntegrationTest
  class FakeDockerClient
    class << self
      attr_accessor :calls, :error_on, :inspect_result

      def reset!
        self.calls = []
        self.error_on = nil
        self.inspect_result = {
          "Id" => "container-acceptance-001",
          "State" => { "Status" => "running" },
        }
      end
    end

    def create_volume(**kwargs)
      record(:create_volume, kwargs)
      raise_error!(:create_volume)

      { "Name" => kwargs.fetch(:name) }
    end

    def create_container(**kwargs)
      record(:create_container, kwargs)
      raise_error!(:create_container)

      { "Id" => "container-acceptance-001" }
    end

    def start_container(**kwargs)
      record(:start_container, kwargs)
      raise_error!(:start_container)

      true
    end

    def stop_container(**kwargs)
      record(:stop_container, kwargs)
      raise_error!(:stop_container)

      true
    end

    def restart_container(**kwargs)
      record(:restart_container, kwargs)
      raise_error!(:restart_container)

      true
    end

    def inspect_container(**kwargs)
      record(:inspect_container, kwargs)
      raise_error!(:inspect_container)

      self.class.inspect_result
    end

    def remove_container(**kwargs)
      record(:remove_container, kwargs)
      raise_error!(:remove_container)

      true
    end

    def remove_volume(**kwargs)
      record(:remove_volume, kwargs)
      raise_error!(:remove_volume)

      true
    end

    private
      def record(name, kwargs)
        self.class.calls << [ name, kwargs ]
      end

      def raise_error!(name)
        return unless self.class.error_on&.first == name

        raise self.class.error_on.last
      end
  end

  setup do
    @original_mc_router_config = Rails.application.config.x.mc_router
    @original_docker_build_client = DockerEngine.method(:build_client)
    @original_runtime_image = Rails.application.config.x.minecraft_runtime.image
    @original_runtime_image_for = MinecraftRuntime.method(:image_for)
    @tmpdir = Dir.mktmpdir("servers-acceptance")

    FakeDockerClient.reset!
    Rails.application.config.x.minecraft_runtime.image = "marctv/minecraft-papermc-server"
    MinecraftRuntime.define_singleton_method(:image_for) do |version_tag:|
      "marctv/minecraft-papermc-server:#{normalize_version_tag(version_tag)}"
    end
    Rails.application.config.x.mc_router = Router::Configuration.new(
      routes_config_path: File.join(@tmpdir, "routes.json"),
      reload_strategy: "watch",
    )
    DockerEngine.define_singleton_method(:build_client) do |**_overrides|
      FakeDockerClient.new
    end
  end

  teardown do
    Rails.application.config.x.mc_router = @original_mc_router_config
    DockerEngine.define_singleton_method(:build_client, @original_docker_build_client)
    Rails.application.config.x.minecraft_runtime.image = @original_runtime_image
    MinecraftRuntime.define_singleton_method(:image_for, @original_runtime_image_for)
    FileUtils.remove_entry(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
  end

  test "accepted create request provisions the server and publishes the route" do
    sign_in_as(users(:two))

    assert_difference("MinecraftServer.count", 1) do
      assert_difference("RouterRoute.count", 1) do
        post servers_url(format: :json), params: {
          minecraft_server: {
            name: "Creative Build",
            hostname: "Creative-Build",
            minecraft_version: "1.21.4",
            memory_mb: 4096,
            disk_mb: 40960,
          },
        }
      end
    end

    assert_response :created

    server_id = response.parsed_body.fetch("server").fetch("id")
    CreateServerJob.perform_now(server_id)

    get server_url(server_id, format: :json)

    assert_response :success

    server = response.parsed_body.fetch("server")
    assert_equal "ready", server.fetch("status")
    assert_equal "creative-build", server.fetch("hostname")
    assert_equal "creative-build.mc.tosukui.xyz:42434", server.fetch("connection_target")
    assert_equal "mc-server-creative-build", server.fetch("runtime").fetch("container_name")
    assert_equal "mc-server-creative-build:25565", server.fetch("runtime").fetch("backend")
    assert_equal true, server.fetch("route").fetch("enabled")
    assert_equal "success", server.fetch("route").fetch("last_apply_status")
    assert_nil server.fetch("last_error_message")
    assert_equal "container-acceptance-001", server.fetch("runtime").fetch("container_id")
    assert_equal "running", server.fetch("runtime").fetch("container_state")

    assert_equal "paper", MinecraftServer.find(server_id).template_kind
    assert_equal(
      [
        [ :create_volume, { name: "mc-data-creative-build", labels: :labels } ],
        [ :create_container, {
          name: "mc-server-creative-build",
          image: "marctv/minecraft-papermc-server:1.21.4",
          env: {
            "MEMORYSIZE" => "3584M",
            "PAPERMC_FLAGS" => "",
          },
          mounts: [ { Type: "volume", Source: "mc-data-creative-build", Target: "/data" } ],
          labels: :labels,
          network_name: "mc_router_net",
          memory_mb: 4096,
        } ],
        [ :start_container, { id: "container-acceptance-001" } ],
        [ :inspect_container, { id_or_name: "container-acceptance-001" } ],
      ],
      normalize_docker_calls(FakeDockerClient.calls),
    )

    mappings = JSON.parse(File.read(File.join(@tmpdir, "routes.json"))).fetch("mappings")
    assert_equal "mc-server-creative-build:25565", mappings.fetch("creative-build.mc.tosukui.xyz")
  end

  test "docker provisioning failure leaves the requested server inspectable in failed state" do
    sign_in_as(users(:two))
    FakeDockerClient.error_on = [ :start_container, DockerEngine::RequestError.new("docker unavailable") ]

    post servers_url(format: :json), params: {
      minecraft_server: {
        name: "Broken Build",
        hostname: "Broken-Build",
        minecraft_version: "1.21.4",
        memory_mb: 4096,
        disk_mb: 20480,
      },
    }

    assert_response :created

    server_id = response.parsed_body.fetch("server").fetch("id")

    error = assert_raises(DockerEngine::RequestError) do
      CreateServerJob.perform_now(server_id)
    end

    assert_equal "docker unavailable", error.message

    get server_url(server_id, format: :json)

    assert_response :success

    server = response.parsed_body.fetch("server")
    assert_equal "failed", server.fetch("status")
    assert_equal "docker unavailable", server.fetch("last_error_message")
    assert_equal false, server.fetch("route").fetch("enabled")
    assert_equal "pending", server.fetch("route").fetch("last_apply_status")
    assert_nil server.fetch("runtime").fetch("container_id")
    assert_equal(
      [
        [ :create_volume, { name: "mc-data-broken-build", labels: :labels } ],
        [ :create_container, {
          name: "mc-server-broken-build",
          image: "marctv/minecraft-papermc-server:1.21.4",
          env: {
            "MEMORYSIZE" => "3584M",
            "PAPERMC_FLAGS" => "",
          },
          mounts: [ { Type: "volume", Source: "mc-data-broken-build", Target: "/data" } ],
          labels: :labels,
          network_name: "mc_router_net",
          memory_mb: 4096,
        } ],
        [ :start_container, { id: "container-acceptance-001" } ],
        [ :remove_container, { id: "container-acceptance-001", force: true } ],
        [ :remove_volume, { name: "mc-data-broken-build" } ],
      ],
      normalize_docker_calls(FakeDockerClient.calls),
    )
  end

  test "owner delete request removes publication and Docker resources" do
    sign_in_as(users(:one))

    assert_difference("MinecraftServer.count", -1) do
      assert_difference("RouterRoute.count", -1) do
        delete server_url(minecraft_servers(:one), format: :json)
      end
    end

    assert_response :no_content
    assert_includes FakeDockerClient.calls, [ :remove_container, { id: "container-001", force: true } ]
    assert_includes FakeDockerClient.calls, [ :remove_volume, { name: "mc-data-main-survival" } ]

    mappings = JSON.parse(File.read(File.join(@tmpdir, "routes.json"))).fetch("mappings")
    assert_not mappings.key?("main-survival.mc.tosukui.xyz")
  end

  test "operator can start a visible server and sync it back to ready" do
    sign_in_as(users(:three))
    server = minecraft_servers(:one)
    server.update_columns(status: "stopped", container_state: "exited")

    post start_server_url(server, format: :json)

    assert_response :success
    assert_equal "starting", response.parsed_body.fetch("server").fetch("status")

    post sync_server_url(server, format: :json)

    assert_response :success
    assert_equal "ready", response.parsed_body.fetch("server").fetch("status")
    assert_equal(
      [
        [ :start_container, { id: "container-001" } ],
        [ :inspect_container, { id_or_name: "container-001" } ],
        [ :inspect_container, { id_or_name: "container-acceptance-001" } ],
      ],
      FakeDockerClient.calls.last(3),
    )
  end

  test "owner can restart and stop a visible server" do
    sign_in_as(users(:one))
    server = minecraft_servers(:one)

    FakeDockerClient.inspect_result = {
      "Id" => "container-001",
      "State" => { "Status" => "running" },
    }

    post restart_server_url(server, format: :json)

    assert_response :success
    assert_equal "restarting", response.parsed_body.fetch("server").fetch("status")
    assert_equal "running", response.parsed_body.fetch("server").fetch("runtime").fetch("container_state")

    post sync_server_url(server, format: :json)

    assert_response :success
    assert_equal "ready", response.parsed_body.fetch("server").fetch("status")

    FakeDockerClient.inspect_result = {
      "Id" => "container-001",
      "State" => { "Status" => "exited" },
    }

    post stop_server_url(server, format: :json)

    assert_response :success
    assert_equal "stopping", response.parsed_body.fetch("server").fetch("status")
    assert_equal "exited", response.parsed_body.fetch("server").fetch("runtime").fetch("container_state")

    post sync_server_url(server, format: :json)

    assert_response :success
    assert_equal "stopped", response.parsed_body.fetch("server").fetch("status")
    assert_equal(
      [
        [ :restart_container, { id: "container-001", timeout_seconds: 30 } ],
        [ :inspect_container, { id_or_name: "container-001" } ],
        [ :inspect_container, { id_or_name: "container-001" } ],
        [ :stop_container, { id: "container-001", timeout_seconds: 30 } ],
        [ :inspect_container, { id_or_name: "container-001" } ],
        [ :inspect_container, { id_or_name: "container-001" } ],
      ],
      FakeDockerClient.calls.last(6),
    )
  end

  private
    def normalize_docker_calls(calls)
      calls.map do |name, payload|
        [
          name,
          payload.deep_dup.tap do |normalized|
            normalized[:labels] = :labels if normalized.key?(:labels)
          end,
        ]
      end
    end
end
