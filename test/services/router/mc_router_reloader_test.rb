require "test_helper"

class Router::McRouterReloaderTest < ActiveSupport::TestCase
  FakeDockerClient = Struct.new(:containers, :signals) do
    def list_containers(filters:, all:)
      self.signals ||= []
      @last_filters = filters
      @last_all = all
      containers
    end

    def signal_container(id:, signal:)
      signals << { id: id, signal: signal }
      true
    end

    attr_reader :last_filters, :last_all
  end

  test "signals the uniquely matched mc-router container" do
    configuration = Router::Configuration.new(
      routes_config_path: "/tmp/mc-router/routes.json",
      reload_strategy: "docker_signal",
      reload_signal: "HUP",
      reload_container_labels: [ "app.kubos.dev/component=mc-router" ],
    )
    docker_client = FakeDockerClient.new(
      [
        { "Id" => "router-123" },
      ],
      [],
    )

    result = Router::McRouterReloader.new(configuration: configuration, docker_client: docker_client).call

    assert_equal true, result
    assert_equal({ label: [ "app.kubos.dev/component=mc-router" ] }, docker_client.last_filters)
    assert_equal false, docker_client.last_all
    assert_equal [ { id: "router-123", signal: "HUP" } ], docker_client.signals
  end

  test "raises when the reload target is missing" do
    configuration = Router::Configuration.new(
      routes_config_path: "/tmp/mc-router/routes.json",
      reload_strategy: "docker_signal",
      reload_container_labels: [ "app.kubos.dev/component=mc-router" ],
    )
    docker_client = FakeDockerClient.new([], [])

    error = assert_raises(Router::ApplyError) do
      Router::McRouterReloader.new(configuration: configuration, docker_client: docker_client).call
    end

    assert_equal "mc_router reload target was not found", error.message
  end

  test "raises when the reload target is ambiguous" do
    configuration = Router::Configuration.new(
      routes_config_path: "/tmp/mc-router/routes.json",
      reload_strategy: "docker_signal",
      reload_container_labels: [ "app.kubos.dev/component=mc-router" ],
    )
    docker_client = FakeDockerClient.new(
      [
        { "Id" => "router-1" },
        { "Id" => "router-2" },
      ],
      [],
    )

    error = assert_raises(Router::ApplyError) do
      Router::McRouterReloader.new(configuration: configuration, docker_client: docker_client).call
    end

    assert_equal "mc_router reload target is ambiguous", error.message
  end

  test "wraps docker errors" do
    configuration = Router::Configuration.new(
      routes_config_path: "/tmp/mc-router/routes.json",
      reload_strategy: "docker_signal",
      reload_container_labels: [ "app.kubos.dev/component=mc-router" ],
    )
    docker_client = Object.new
    docker_client.define_singleton_method(:list_containers) do |filters:, all:|
      raise DockerEngine::ConnectionError, "socket failed"
    end

    error = assert_raises(Router::ApplyError) do
      Router::McRouterReloader.new(configuration: configuration, docker_client: docker_client).call
    end

    assert_equal "mc_router docker-signal reload failed: socket failed", error.message
  end
end
