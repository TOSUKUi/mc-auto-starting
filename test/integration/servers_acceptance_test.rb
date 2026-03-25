require "test_helper"
require "json"
require "tmpdir"

class ServersAcceptanceTest < ActionDispatch::IntegrationTest
  class FakeDockerClient
    class << self
      attr_accessor :calls, :error_on

      def reset!
        self.calls = []
        self.error_on = nil
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

    def inspect_container(**kwargs)
      record(:inspect_container, kwargs)
      raise_error!(:inspect_container)

      {
        "Id" => "container-acceptance-001",
        "State" => { "Status" => "running" },
      }
    end

    def remove_container(**kwargs)
      record(:remove_container, kwargs)
      true
    end

    def remove_volume(**kwargs)
      record(:remove_volume, kwargs)
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

  class FakeExecutionProviderClient
    class << self
      attr_accessor :created_requests, :create_result, :create_error, :deleted_ids, :power_calls, :status_result

      def reset!
        self.created_requests = []
        self.create_result = nil
        self.create_error = nil
        self.deleted_ids = []
        self.power_calls = []
        self.status_result = nil
      end
    end

    def initialize(configuration:)
      @configuration = configuration
    end

    def create_server(request)
      self.class.created_requests << request
      raise self.class.create_error if self.class.create_error

      self.class.create_result || raise("FakeExecutionProviderClient.create_result must be configured")
    end

    def delete_server(provider_server_id)
      self.class.deleted_ids << provider_server_id
      true
    end

    def start_server(identifier)
      self.class.power_calls << [ :start, identifier ]
      lifecycle_result(identifier, "start")
    end

    def stop_server(identifier)
      self.class.power_calls << [ :stop, identifier ]
      lifecycle_result(identifier, "stop")
    end

    def restart_server(identifier)
      self.class.power_calls << [ :restart, identifier ]
      lifecycle_result(identifier, "restart")
    end

    def fetch_status(identifier)
      self.class.power_calls << [ :sync, identifier ]
      self.class.status_result || raise("FakeExecutionProviderClient.status_result must be configured")
    end

    private
      attr_reader :configuration

      def lifecycle_result(identifier, action)
        ExecutionProvider::LifecycleResult.new(
          provider_server_id: identifier,
          action: action,
          accepted: true,
          raw: { provider_name: configuration.provider_name },
        )
      end
  end

  setup do
    @original_execution_provider_config = Rails.application.config.x.execution_provider
    @original_mc_router_config = Rails.application.config.x.mc_router
    @original_docker_build_client = DockerEngine.method(:build_client)
    @tmpdir = Dir.mktmpdir("servers-acceptance")

    FakeDockerClient.reset!
    FakeExecutionProviderClient.reset!
    Rails.application.config.x.execution_provider = acceptance_provider_config
    Rails.application.config.x.mc_router = Router::Configuration.new(
      routes_config_path: File.join(@tmpdir, "routes.json"),
      reload_strategy: "watch",
    )
    DockerEngine.define_singleton_method(:build_client) do |**_overrides|
      FakeDockerClient.new
    end
  end

  teardown do
    Rails.application.config.x.execution_provider = @original_execution_provider_config
    Rails.application.config.x.mc_router = @original_mc_router_config
    DockerEngine.define_singleton_method(:build_client, @original_docker_build_client)
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
            memory_mb: 8192,
            disk_mb: 40960,
            template_kind: "velocity",
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
          image: "itzg/minecraft-server",
          env: {
            "EULA" => "TRUE",
            "TYPE" => "PAPER",
            "VERSION" => "1.21.4",
            "MEMORY" => "8192M",
          },
          mounts: [ { Type: "volume", Source: "mc-data-creative-build", Target: "/data" } ],
          labels: :labels,
          network_name: "mc_router_net",
          memory_mb: 8192,
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
        template_kind: "velocity",
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
          image: "itzg/minecraft-server",
          env: {
            "EULA" => "TRUE",
            "TYPE" => "PAPER",
            "VERSION" => "1.21.4",
            "MEMORY" => "4096M",
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

  test "owner delete request removes publication and provider record" do
    sign_in_as(users(:one))

    assert_difference("MinecraftServer.count", -1) do
      assert_difference("RouterRoute.count", -1) do
        delete server_url(minecraft_servers(:one), format: :json)
      end
    end

    assert_response :no_content
    assert_equal [ "srv-001" ], FakeExecutionProviderClient.deleted_ids

    mappings = JSON.parse(File.read(File.join(@tmpdir, "routes.json"))).fetch("mappings")
    assert_not mappings.key?("main-survival.mc.tosukui.xyz")
  end

  test "operator can start a visible server and sync it back to ready" do
    sign_in_as(users(:three))
    server = minecraft_servers(:one)
    server.update_columns(status: "stopped")
    FakeExecutionProviderClient.status_result = ExecutionProvider::ServerStatus.new(
      provider_server_id: server.provider_server_identifier,
      state: "running",
      rails_status: "ready",
      raw: {},
    )

    post start_server_url(server, format: :json)

    assert_response :success
    assert_equal "starting", response.parsed_body.fetch("server").fetch("status")

    post sync_server_url(server, format: :json)

    assert_response :success
    assert_equal "ready", response.parsed_body.fetch("server").fetch("status")
    assert_equal [ [ :start, "abc12345" ], [ :sync, "abc12345" ] ], FakeExecutionProviderClient.power_calls
  end

  private
    def acceptance_provider_config
      ExecutionProvider::Configuration.new(
        provider_name: "acceptance_stub",
        client_class_name: "ServersAcceptanceTest::FakeExecutionProviderClient",
        provisioning_templates: {
          paper: {
            owner_id: 40,
            node_id: 2,
            egg_id: 7,
            allocation_id: 21,
            environment: {
              server_jarfile: "paper.jar",
            },
          },
          velocity: {
            owner_id: 40,
            node_id: 2,
            egg_id: 8,
            allocation_id: 22,
            environment: {
              server_jarfile: "velocity.jar",
            },
          },
        },
      )
    end

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
