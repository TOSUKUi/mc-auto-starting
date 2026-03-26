require "test_helper"

class Router::ConfigurationTest < ActiveSupport::TestCase
  test "defaults to watch-based reload strategy" do
    configuration = Router::Configuration.new(routes_config_path: "/tmp/mc-router/routes.json")

    assert_equal "watch", configuration.reload_strategy
    assert_equal true, configuration.watch?
    assert_equal false, configuration.command?
    assert_equal false, configuration.docker_signal?
    assert_equal false, configuration.manual?
    assert_equal "HUP", configuration.reload_signal
    assert_equal [], configuration.reload_container_labels
  end

  test "accepts docker-signal configuration when labels are provided" do
    configuration = Router::Configuration.new(
      routes_config_path: "/tmp/mc-router/routes.json",
      reload_strategy: "docker_signal",
      reload_container_labels: [ "app.kubos.dev/component=mc-router" ],
    )

    assert_equal "docker_signal", configuration.reload_strategy
    assert_equal false, configuration.command?
    assert_equal true, configuration.docker_signal?
    assert_equal false, configuration.manual?
    assert_equal [ "app.kubos.dev/component=mc-router" ], configuration.reload_container_labels
  end

  test "rejects unsupported reload strategies" do
    error = assert_raises(Router::ConfigurationError) do
      Router::Configuration.new(
        routes_config_path: "/tmp/mc-router/routes.json",
        reload_strategy: "sighup",
      )
    end

    assert_equal "mc_router reload_strategy must be one of: watch, command, docker_signal, manual", error.message
  end

  test "requires a command when command reload strategy is configured" do
    error = assert_raises(Router::ConfigurationError) do
      Router::Configuration.new(
        routes_config_path: "/tmp/mc-router/routes.json",
        reload_strategy: "command",
      )
    end

    assert_equal "mc_router reload_command is required when reload_strategy=command", error.message
  end

  test "requires reload_container_labels when docker_signal reload strategy is configured" do
    error = assert_raises(Router::ConfigurationError) do
      Router::Configuration.new(
        routes_config_path: "/tmp/mc-router/routes.json",
        reload_strategy: "docker_signal",
      )
    end

    assert_equal "mc_router reload_container_labels is required when reload_strategy=docker_signal", error.message
  end
end
