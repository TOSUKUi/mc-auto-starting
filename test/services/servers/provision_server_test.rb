require "test_helper"

class Servers::ProvisionServerTest < ActiveSupport::TestCase
  FakeProviderClient = Struct.new(:provider_server) do
    def create_server(_request)
      provider_server
    end
  end

  FailingProviderClient = Struct.new(:error) do
    def create_server(_request)
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
    @original_execution_provider_config = Rails.application.config.x.execution_provider
    Rails.application.config.x.execution_provider = ExecutionProvider::Configuration.new(
      provider_name: "pterodactyl",
      provisioning_templates: {
        paper: {
          owner_id: 40,
          node_id: 2,
          egg_id: 7,
          allocation_id: 21,
          environment: {
            server_jarfile: "paper.jar",
          },
        },
      },
    )
  end

  teardown do
    Rails.application.config.x.execution_provider = @original_execution_provider_config
  end

  test "provisions the provider server, applies the route, and marks the server ready" do
    server = minecraft_servers(:two)
    server.update!(template_kind: "paper", last_error_message: "old failure")

    provider_server = ExecutionProvider::ProviderServer.new(
      provider_server_id: "321",
      identifier: "abcd1234",
      name: server.name,
      backend_host: "wings.internal",
      backend_port: 25565,
      node_id: 2,
      allocation_id: 21,
      raw: {},
    )
    router_applier = FakeRouterApplier.new([])

    Servers::ProvisionServer.new(
      server: server,
      provider_client: FakeProviderClient.new(provider_server),
      router_applier: router_applier,
    ).call

    server.reload

    assert_equal "ready", server.status
    assert_equal "321", server.provider_server_id
    assert_equal "abcd1234", server.provider_server_identifier
    assert_equal "wings.internal", server.backend_host
    assert_equal 25565, server.backend_port
    assert_nil server.last_error_message
    assert_equal true, server.router_route.enabled
    assert_equal "success", server.router_route.last_apply_status
    assert_not_nil server.router_route.last_applied_at
    assert_equal 1, router_applier.calls.size
  end

  test "keeps the provisional server record and marks it failed when provider provisioning fails" do
    server = minecraft_servers(:two)
    server.update!(template_kind: "paper")
    provider_error = ExecutionProvider::RequestError.new("provider unavailable")

    assert_no_difference("MinecraftServer.count") do
      assert_no_difference("RouterRoute.count") do
        assert_raises(ExecutionProvider::RequestError) do
          Servers::ProvisionServer.new(
            server: server,
            provider_client: FailingProviderClient.new(provider_error),
          ).call
        end
      end
    end

    server.reload

    assert_equal "failed", server.status
    assert_equal "provider unavailable", server.last_error_message
    assert_equal false, server.router_route.enabled
    assert_equal "pending", server.router_route.last_apply_status
    assert MinecraftServer.exists?(server.id)
  end

  test "marks the server unpublished when route apply fails" do
    server = minecraft_servers(:two)
    server.update!(template_kind: "paper")

    provider_server = ExecutionProvider::ProviderServer.new(
      provider_server_id: "321",
      identifier: "abcd1234",
      name: server.name,
      backend_host: "wings.internal",
      backend_port: 25565,
      node_id: 2,
      allocation_id: 21,
      raw: {},
    )
    failing_applier = Object.new
    failing_applier.define_singleton_method(:call) do |routes:|
      raise Router::ApplyError, "reload failed"
    end

    assert_raises(Router::ApplyError) do
      Servers::ProvisionServer.new(
        server: server,
        provider_client: FakeProviderClient.new(provider_server),
        router_applier: failing_applier,
      ).call
    end

    server.reload

    assert_equal "unpublished", server.status
    assert_equal "321", server.provider_server_id
    assert_equal "abcd1234", server.provider_server_identifier
    assert_equal "reload failed", server.last_error_message
    assert_equal false, server.router_route.enabled
    assert_equal "failed", server.router_route.last_apply_status
  end
end
