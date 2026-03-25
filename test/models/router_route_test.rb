require "test_helper"

class RouterRouteTest < ActiveSupport::TestCase
  test "belongs to minecraft_server" do
    route = router_routes(:one)

    assert_equal minecraft_servers(:one), route.minecraft_server
  end

  test "defines allowed apply statuses" do
    assert RouterRoute.last_apply_statuses.key?("pending")
    assert RouterRoute.last_apply_statuses.key?("success")
    assert RouterRoute.last_apply_statuses.key?("failed")
  end

  test "defines allowed healthcheck statuses" do
    assert RouterRoute.last_healthcheck_statuses.key?("unknown")
    assert RouterRoute.last_healthcheck_statuses.key?("healthy")
    assert RouterRoute.last_healthcheck_statuses.key?("unreachable")
    assert RouterRoute.last_healthcheck_statuses.key?("rejected")
  end

  test "defaults to disabled pending unknown state" do
    server = MinecraftServer.create!(
      owner: users(:one),
      name: "Snapshot Server",
      hostname: "snapshot-server",
      status: :provisioning,
      minecraft_version: "1.21.4",
      memory_mb: 2048,
      disk_mb: 10240,
      template_kind: "paper"
    )
    route = RouterRoute.new(minecraft_server: server)

    assert route.valid?
    assert_equal false, route.enabled
    assert_equal "unpublished", route.publication_state
    assert_equal "pending", route.last_apply_status
    assert_equal "unknown", route.last_healthcheck_status
  end

  test "rejects duplicate route for the same server" do
    route = RouterRoute.new(minecraft_server: minecraft_servers(:one), enabled: false)

    assert_not route.valid?
    assert_includes route.errors[:minecraft_server_id], "has already been taken"
  end

  test "derives publication fields from the related server" do
    route = router_routes(:one)

    assert_equal "main-survival.mc.tosukui.xyz", route.server_address
    assert_equal "mc-server-main-survival:25565", route.backend
    assert_equal true, route.desired_enabled?
    assert_equal true, route.publishable?
    assert_equal "published", route.publication_state
  end

  test "returns failed publication state when the last apply failed" do
    route = router_routes(:one)
    route.last_apply_status = :failed

    assert_equal "failed", route.publication_state
  end

  test "returns invalid publication state when the server should not be routed" do
    route = router_routes(:one)
    route.minecraft_server.update!(status: :failed)

    assert_equal false, route.publishable?
    assert_equal "invalid", route.publication_state
  end
end
