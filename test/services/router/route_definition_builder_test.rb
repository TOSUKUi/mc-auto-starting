require "test_helper"

class Router::RouteDefinitionBuilderTest < ActiveSupport::TestCase
  test "builds a route definition from the server fqdn and backend target" do
    definition = Router::RouteDefinitionBuilder.new(router_route: router_routes(:one)).call

    assert_equal "main-survival.mc.tosukui.xyz", definition.server_address
    assert_equal "mc-server-main-survival:25565", definition.backend
  end

  test "rejects routes that are not publishable" do
    router_routes(:two).update_columns(enabled: true)

    error = assert_raises(ArgumentError) do
      Router::RouteDefinitionBuilder.new(router_route: router_routes(:two)).call
    end

    assert_equal "router_route is not publishable", error.message
  end
end
