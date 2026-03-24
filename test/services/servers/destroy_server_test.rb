require "test_helper"

class Servers::DestroyServerTest < ActiveSupport::TestCase
  FakeProviderClient = Struct.new(:deleted_ids) do
    def delete_server(provider_server_id)
      deleted_ids << provider_server_id
      true
    end
  end

  FailingProviderClient = Struct.new(:error) do
    def delete_server(_provider_server_id)
      raise error
    end
  end

  FakeRouterApplier = Struct.new(:calls) do
    def call(routes:)
      calls << routes
      Router::ConfigApplier::ApplyResult.new(path: "/tmp/routes.json", reload_strategy: "watch", reloaded: true)
    end
  end

  test "unpublishes the route, deletes the provider server, and removes the record" do
    server = minecraft_servers(:one)
    router_applier = FakeRouterApplier.new([])
    provider_client = FakeProviderClient.new([])

    assert_difference("MinecraftServer.count", -1) do
      assert_difference("RouterRoute.count", -1) do
        Servers::DestroyServer.new(
          server: server,
          provider_client: provider_client,
          router_applier: router_applier,
        ).call
      end
    end

    assert_equal [ "srv-001" ], provider_client.deleted_ids
    assert_equal 1, router_applier.calls.size
    assert_not MinecraftServer.exists?(server.id)
  end

  test "keeps the deleting record when provider delete fails after route unpublish" do
    server = minecraft_servers(:one)
    router_applier = FakeRouterApplier.new([])
    provider_error = ExecutionProvider::RequestError.new("delete failed")

    assert_no_difference("MinecraftServer.count") do
      assert_no_difference("RouterRoute.count") do
        assert_raises(ExecutionProvider::RequestError) do
          Servers::DestroyServer.new(
            server: server,
            provider_client: FailingProviderClient.new(provider_error),
            router_applier: router_applier,
          ).call
        end
      end
    end

    server.reload

    assert_equal "deleting", server.status
    assert_equal false, server.router_route.enabled
    assert_equal "success", server.router_route.last_apply_status
    assert_not_nil server.router_route.last_applied_at
  end
end
