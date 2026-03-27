require "test_helper"
require "tmpdir"

class Router::PublicationAuditTest < ActiveSupport::TestCase
  test "passes when the enabled route exists with the expected backend" do
    route = router_routes(:one)

    Dir.mktmpdir do |dir|
      path = File.join(dir, "routes.json")
      File.write(path, {
        "default-server" => nil,
        "mappings" => {
          route.server_address => route.backend,
        },
      }.to_json)

      result = Router::PublicationAudit.new(
        configuration: Router::Configuration.new(routes_config_path: path, reload_strategy: "manual"),
      ).call(router_route: route)

      assert_equal true, result.ok
      assert_nil result.message
      assert_equal "success", route.reload.last_apply_status
    end
  end

  test "marks the route failed when the enabled route is missing from the rendered config" do
    route = router_routes(:one)

    Dir.mktmpdir do |dir|
      path = File.join(dir, "routes.json")
      File.write(path, { "default-server" => nil, "mappings" => {} }.to_json)

      result = Router::PublicationAudit.new(
        configuration: Router::Configuration.new(routes_config_path: path, reload_strategy: "manual"),
      ).call(router_route: route)

      assert_equal false, result.ok
      assert_match "公開設定の反映を確認できませんでした", result.message
      assert_equal "failed", route.reload.last_apply_status
    end
  end

  test "marks the route failed when a disabled route remains in the rendered config" do
    route = router_routes(:one)
    route.update!(enabled: false, last_apply_status: :success)

    Dir.mktmpdir do |dir|
      path = File.join(dir, "routes.json")
      File.write(path, {
        "default-server" => nil,
        "mappings" => {
          route.server_address => route.backend,
        },
      }.to_json)

      result = Router::PublicationAudit.new(
        configuration: Router::Configuration.new(routes_config_path: path, reload_strategy: "manual"),
      ).call(router_route: route)

      assert_equal false, result.ok
      assert_match "非公開のはずのサーバー", result.message
      assert_equal "failed", route.reload.last_apply_status
    end
  end
end
