require "test_helper"

class Servers::ProvisionServerTest < ActiveSupport::TestCase
  FakeDockerClient = Struct.new(:calls, :container_id, :inspect_state, :error_on, keyword_init: true) do
    def create_volume(**kwargs)
      record(:create_volume, kwargs)
      raise_error!(:create_volume)

      { "Name" => kwargs.fetch(:name) }
    end

    def create_container(**kwargs)
      record(:create_container, kwargs)
      raise_error!(:create_container)

      { "Id" => container_id }
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
        "Id" => container_id,
        "State" => { "Status" => inspect_state },
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

    def pull_image(**kwargs)
      record(:pull_image, kwargs)
      raise_error!(:pull_image)

      true
    end

    private
      def record(name, kwargs)
        calls << [ name, kwargs ]
      end

      def raise_error!(name)
        return unless error_on&.first == name

        error = error_on.last
        self.error_on = nil if error_on.is_a?(Array)
        raise error
      end
  end

  FakeRouterApplier = Struct.new(:calls) do
    def call(routes:)
      calls << routes
      Router::ConfigApplier::ApplyResult.new(path: "/tmp/routes.json", reload_strategy: "watch", reloaded: true)
    end
  end

  setup do
    @original_runtime_image = Rails.application.config.x.minecraft_runtime.image
    Rails.application.config.x.minecraft_runtime.image = "itzg/minecraft-server"
  end

  teardown do
    Rails.application.config.x.minecraft_runtime.image = @original_runtime_image
  end

  test "creates Docker resources publishes the route and marks the server ready" do
    server = minecraft_servers(:two)
    server.update!(template_kind: "paper", last_error_message: "old failure")
    docker_client = FakeDockerClient.new(
      calls: [],
      container_id: "container-900",
      inspect_state: "running",
    )
    router_applier = FakeRouterApplier.new([])

    Servers::ProvisionServer.new(
      server: server,
      docker_client: docker_client,
      router_applier: router_applier,
    ).call

    server.reload

    assert_equal "ready", server.status
    assert_equal "container-900", server.container_id
    assert_equal "running", server.container_state
    assert_not_nil server.last_started_at
    assert_nil server.last_error_message
    assert_equal true, server.router_route.enabled
    assert_equal "success", server.router_route.last_apply_status
    assert_not_nil server.router_route.last_applied_at

    assert_equal [ :create_volume, { name: "mc-data-event-server", labels: DockerEngine::ManagedLabels.for_server(minecraft_server: server) } ], docker_client.calls.fetch(0)
    assert_equal [ :start_container, { id: "container-900" } ], docker_client.calls.fetch(2)
    assert_equal [ :inspect_container, { id_or_name: "container-900" } ], docker_client.calls.fetch(3)

    create_call = docker_client.calls.fetch(1)
    assert_equal :create_container, create_call.fetch(0)
    assert_equal "mc-server-event-server", create_call.fetch(1).fetch(:name)
    assert_equal "itzg/minecraft-server", create_call.fetch(1).fetch(:image)
    assert_equal(
      {
        "HARDCORE" => "FALSE",
        "DIFFICULTY" => "easy",
        "MODE" => "survival",
        "MAX_PLAYERS" => "20",
        "PVP" => "TRUE",
        "EULA" => "TRUE",
        "TYPE" => "PAPER",
        "VERSION" => "1.21.4",
        "MEMORY" => "3584M",
        "ENABLE_RCON" => "TRUE",
        "ENABLE_WHITELIST" => "TRUE",
        "WHITELIST" => "",
        "EXISTING_WHITELIST_FILE" => "SYNCHRONIZE",
        "RCON_PORT" => "25575",
        "RCON_PASSWORD" => server.rcon_password,
      },
      create_call.fetch(1).fetch(:env),
    )
    assert_equal [ { Type: "volume", Source: "mc-data-event-server", Target: "/data" } ], create_call.fetch(1).fetch(:mounts)
    assert_equal MinecraftRuntime.network_name, create_call.fetch(1).fetch(:network_name)
    assert_equal 4096, create_call.fetch(1).fetch(:memory_mb)
    assert_equal 1, router_applier.calls.size
  end

  test "cleans up managed resources and marks the server failed when Docker provisioning fails" do
    server = minecraft_servers(:two)
    server.update!(template_kind: "paper")
    docker_client = FakeDockerClient.new(
      calls: [],
      container_id: "container-900",
      inspect_state: "created",
      error_on: [ :start_container, DockerEngine::RequestError.new("docker unavailable") ],
    )

    error = assert_raises(DockerEngine::RequestError) do
      Servers::ProvisionServer.new(
        server: server,
        docker_client: docker_client,
      ).call
    end

    server.reload

    assert_equal "docker unavailable", error.message
    assert_equal "failed", server.status
    assert_nil server.container_id
    assert_nil server.container_state
    assert_nil server.last_started_at
    assert_equal "docker unavailable", server.last_error_message
    assert_equal false, server.router_route.enabled
    assert_equal "pending", server.router_route.last_apply_status
    assert_includes docker_client.calls, [ :remove_container, { id: "container-900", force: true } ]
    assert_includes docker_client.calls, [ :remove_volume, { name: "mc-data-event-server" } ]
  end

  test "marks the server unpublished when route apply fails after Docker provisioning" do
    server = minecraft_servers(:two)
    server.update!(template_kind: "paper")
    docker_client = FakeDockerClient.new(
      calls: [],
      container_id: "container-900",
      inspect_state: "running",
    )
    failing_applier = Object.new
    failing_applier.define_singleton_method(:call) do |routes:|
      raise Router::ApplyError, "reload failed"
    end

    assert_raises(Router::ApplyError) do
      Servers::ProvisionServer.new(
        server: server,
        docker_client: docker_client,
        router_applier: failing_applier,
      ).call
    end

    server.reload

    assert_equal "unpublished", server.status
    assert_equal "container-900", server.container_id
    assert_equal "running", server.container_state
    assert_equal "reload failed", server.last_error_message
    assert_equal false, server.router_route.enabled
    assert_equal "failed", server.router_route.last_apply_status
  end

  test "pulls the image and retries container create when the image is missing" do
    server = minecraft_servers(:two)
    docker_client = FakeDockerClient.new(
      calls: [],
      container_id: "container-901",
      inspect_state: "running",
      error_on: [ :create_container, DockerEngine::NotFoundError.new("No such image: itzg/minecraft-server") ],
    )

    Servers::ProvisionServer.new(
      server: server,
      docker_client: docker_client,
      router_applier: FakeRouterApplier.new([]),
    ).call

    assert_equal [ :pull_image, { image: "itzg/minecraft-server" } ], docker_client.calls.fetch(2)
    assert_equal :create_container, docker_client.calls.fetch(3).fetch(0)
  end

  test "uses the vanilla runtime image and env when the runtime family is vanilla" do
    server = minecraft_servers(:two)
    server.update!(template_kind: "vanilla", minecraft_version: "latest", memory_mb: 2048)
    docker_client = FakeDockerClient.new(
      calls: [],
      container_id: "container-902",
      inspect_state: "running",
    )

    Servers::ProvisionServer.new(
      server: server,
      docker_client: docker_client,
      router_applier: FakeRouterApplier.new([]),
    ).call

    create_call = docker_client.calls.fetch(1)
    assert_equal "itzg/minecraft-server", create_call.fetch(1).fetch(:image)
    assert_equal(
      {
        "HARDCORE" => "FALSE",
        "DIFFICULTY" => "easy",
        "MODE" => "survival",
        "MAX_PLAYERS" => "20",
        "PVP" => "TRUE",
        "EULA" => "TRUE",
        "TYPE" => "VANILLA",
        "VERSION" => "latest",
        "MEMORY" => "1536M",
        "ENABLE_RCON" => "TRUE",
        "ENABLE_WHITELIST" => "TRUE",
        "WHITELIST" => "",
        "EXISTING_WHITELIST_FILE" => "SYNCHRONIZE",
        "RCON_PORT" => "25575",
        "RCON_PASSWORD" => server.rcon_password,
      },
      create_call.fetch(1).fetch(:env),
    )
  end
end
