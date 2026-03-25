require "json"
require "test_helper"

class Router::ConfigApplierTest < ActiveSupport::TestCase
  test "writes rendered config to the configured file path" do
    Dir.mktmpdir do |dir|
      config_path = File.join(dir, "routes.json")
      configuration = Router::Configuration.new(routes_config_path: config_path)

      result = Router::ConfigApplier.new(configuration: configuration).call(routes: [ router_routes(:one), router_routes(:two) ])
      payload = JSON.parse(File.read(config_path))

      assert_equal config_path, result.path
      assert_equal "watch", result.reload_strategy
      assert_equal true, result.reloaded
      assert_equal({ "main-survival.mc.tosukui.xyz" => "mc-server-main-survival:25565" }, payload.fetch("mappings"))
    end
  end

  test "runs the configured reload command when requested" do
    Dir.mktmpdir do |dir|
      config_path = File.join(dir, "routes.json")
      marker_path = File.join(dir, "reload.marker")
      configuration = Router::Configuration.new(
        routes_config_path: config_path,
        reload_strategy: "command",
        reload_command: "touch #{marker_path}",
      )

      result = Router::ConfigApplier.new(configuration: configuration).call(routes: [ router_routes(:one) ])

      assert_equal true, result.reloaded
      assert File.exist?(marker_path)
    end
  end

  test "raises when the reload command fails" do
    Dir.mktmpdir do |dir|
      config_path = File.join(dir, "routes.json")
      configuration = Router::Configuration.new(
        routes_config_path: config_path,
        reload_strategy: "command",
        reload_command: "/bin/false",
      )

      error = assert_raises(Router::ApplyError) do
        Router::ConfigApplier.new(configuration: configuration).call(routes: [ router_routes(:one) ])
      end

      assert_match "mc_router reload command failed", error.message
    end
  end
end
