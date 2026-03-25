require "test_helper"

class Router::PublicationSyncTest < ActiveSupport::TestCase
  FakeApplier = Struct.new(:calls) do
    def call(routes:)
      calls << routes
      Router::ConfigApplier::ApplyResult.new(path: "/tmp/routes.json", reload_strategy: "watch", reloaded: true)
    end
  end

  test "enables the route and records a successful apply" do
    route = router_routes(:two)
    applier = FakeApplier.new([])

    Router::PublicationSync.new(
      router_route: route,
      enabled: true,
      applier: applier,
    ).call

    route.reload

    assert_equal true, route.enabled
    assert_equal "success", route.last_apply_status
    assert_not_nil route.last_applied_at
    assert_equal 1, applier.calls.size
  end

  test "disables the route and records a successful apply" do
    route = router_routes(:one)
    applier = FakeApplier.new([])

    Router::PublicationSync.new(
      router_route: route,
      enabled: false,
      applier: applier,
    ).call

    route.reload

    assert_equal false, route.enabled
    assert_equal "success", route.last_apply_status
    assert_not_nil route.last_applied_at
    assert_equal 1, applier.calls.size
  end

  test "rolls back enabled publication to disabled when apply fails" do
    route = router_routes(:two)
    failing_applier = Object.new
    failing_applier.define_singleton_method(:call) do |routes:|
      raise Router::ApplyError, "reload failed"
    end

    error = assert_raises(Router::ApplyError) do
      Router::PublicationSync.new(
        router_route: route,
        enabled: true,
        applier: failing_applier,
      ).call
    end

    route.reload

    assert_equal "reload failed", error.message
    assert_equal false, route.enabled
    assert_equal "failed", route.last_apply_status
  end

  test "keeps the route disabled when unpublish apply fails" do
    route = router_routes(:one)
    failing_applier = Object.new
    failing_applier.define_singleton_method(:call) do |routes:|
      raise Router::ApplyError, "reload failed"
    end

    assert_raises(Router::ApplyError) do
      Router::PublicationSync.new(
        router_route: route,
        enabled: false,
        applier: failing_applier,
      ).call
    end

    route.reload

    assert_equal false, route.enabled
    assert_equal "failed", route.last_apply_status
  end
end
