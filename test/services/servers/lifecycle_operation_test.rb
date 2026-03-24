require "test_helper"

class Servers::LifecycleOperationTest < ActiveSupport::TestCase
  FakeProviderClient = Struct.new(:calls, :status_result, keyword_init: true) do
    def start_server(identifier)
      calls << [ :start, identifier ]
      accepted_result(identifier, "start")
    end

    def stop_server(identifier)
      calls << [ :stop, identifier ]
      accepted_result(identifier, "stop")
    end

    def restart_server(identifier)
      calls << [ :restart, identifier ]
      accepted_result(identifier, "restart")
    end

    def fetch_status(identifier)
      calls << [ :sync, identifier ]
      status_result
    end

    private
      def accepted_result(identifier, action)
        ExecutionProvider::LifecycleResult.new(
          provider_server_id: identifier,
          action: action,
          accepted: true,
          raw: {},
        )
      end
  end

  test "start uses provider_server_identifier and marks the server starting" do
    server = minecraft_servers(:one)
    server.update_columns(status: "stopped")
    provider_client = FakeProviderClient.new(calls: [])

    result = Servers::StartServer.new(server: server, provider_client: provider_client).call

    assert_equal server, result
    assert_equal [ [ :start, "abc12345" ] ], provider_client.calls
    assert_equal "starting", server.reload.status
  end

  test "stop uses provider_server_identifier and marks the server stopping" do
    server = minecraft_servers(:one)
    provider_client = FakeProviderClient.new(calls: [])

    Servers::StopServer.new(server: server, provider_client: provider_client).call

    assert_equal [ [ :stop, "abc12345" ] ], provider_client.calls
    assert_equal "stopping", server.reload.status
  end

  test "restart uses provider_server_identifier and marks the server restarting" do
    server = minecraft_servers(:one)
    provider_client = FakeProviderClient.new(calls: [])

    Servers::RestartServer.new(server: server, provider_client: provider_client).call

    assert_equal [ [ :restart, "abc12345" ] ], provider_client.calls
    assert_equal "restarting", server.reload.status
  end

  test "sync maps provider status onto the server status" do
    server = minecraft_servers(:one)
    server.update!(status: :stopping)
    provider_client = FakeProviderClient.new(
      calls: [],
      status_result: ExecutionProvider::ServerStatus.new(
        provider_server_id: "abc12345",
        state: "offline",
        rails_status: "stopped",
        raw: {},
      ),
    )

    Servers::SyncServerState.new(server: server, provider_client: provider_client).call

    assert_equal [ [ :sync, "abc12345" ] ], provider_client.calls
    assert_equal "stopped", server.reload.status
  end

  test "sync degrades the server on conflicting provider state" do
    server = minecraft_servers(:one)
    server.update!(status: :restarting)
    provider_client = FakeProviderClient.new(
      calls: [],
      status_result: ExecutionProvider::ServerStatus.new(
        provider_server_id: "abc12345",
        state: "starting",
        rails_status: "starting",
        raw: {},
      ),
    )

    Servers::SyncServerState.new(server: server, provider_client: provider_client).call

    assert_equal "degraded", server.reload.status
  end

  test "sync degrades the server when the provider no longer finds it" do
    server = minecraft_servers(:one)
    provider_client = Object.new
    provider_client.define_singleton_method(:fetch_status) do |_identifier|
      raise ExecutionProvider::NotFoundError, "missing"
    end

    Servers::SyncServerState.new(server: server, provider_client: provider_client).call

    assert_equal "degraded", server.reload.status
  end

  test "lifecycle actions require the provider server identifier" do
    server = minecraft_servers(:one)
    server.update_columns(provider_server_identifier: nil)

    error = assert_raises(ExecutionProvider::ValidationError) do
      Servers::StartServer.new(server: server, provider_client: FakeProviderClient.new(calls: [])).call
    end

    assert_equal "provider_server_identifier is required for lifecycle operations", error.message
  end
end
