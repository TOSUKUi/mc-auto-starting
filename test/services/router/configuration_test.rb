require "test_helper"

class Router::ConfigurationTest < ActiveSupport::TestCase
  test "defaults to watch-based reload strategy" do
    configuration = Router::Configuration.new(routes_config_path: "/tmp/mc-router/routes.json")

    assert_equal "watch", configuration.reload_strategy
    assert_equal true, configuration.watch?
    assert_equal false, configuration.command?
    assert_equal false, configuration.manual?
  end

  test "rejects unsupported reload strategies" do
    error = assert_raises(Router::ConfigurationError) do
      Router::Configuration.new(
        routes_config_path: "/tmp/mc-router/routes.json",
        reload_strategy: "sighup",
      )
    end

    assert_equal "mc_router reload_strategy must be one of: watch, command, manual", error.message
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
end
