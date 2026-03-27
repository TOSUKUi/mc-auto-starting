require "test_helper"

class ServersControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
  end

  teardown do
    clear_enqueued_jobs
  end

  test "redirects unauthenticated users to login for index" do
    get servers_url

    assert_redirected_to login_path
  end

  test "root redirects unauthenticated users to login" do
    get root_url

    assert_redirected_to login_path
  end

  test "root serves the server index for authenticated users" do
    sign_in_as(users(:one))

    get root_url

    assert_response :success
  end

  test "index returns only owned and member servers" do
    sign_in_as(users(:two))

    get servers_url(format: :json)

    assert_response :success
    assert_equal [ minecraft_servers(:two).id, minecraft_servers(:one).id ], response.parsed_body.fetch("servers").map { |server| server.fetch("id") }
  end

  test "index returns server summary fields for the listing UI" do
    sign_in_as(users(:two))

    get servers_url(format: :json)

    assert_response :success

    summary = response.parsed_body.fetch("summary")
    assert_equal 2, summary.fetch("total")
    assert_equal 1, summary.fetch("owned")
    assert_equal 1, summary.fetch("member")
    assert_equal 1, summary.fetch("ready")
    assert_equal 1, summary.fetch("attention_needed")

    visible_server = response.parsed_body.fetch("servers").detect { |server| server.fetch("id") == minecraft_servers(:one).id }

    assert_equal "main-survival", visible_server.fetch("hostname")
    assert_equal "main-survival.mc.tosukui.xyz", visible_server.fetch("fqdn")
    assert_equal "main-survival.mc.tosukui.xyz:42434", visible_server.fetch("connection_target")
    assert_equal "paper", visible_server.fetch("runtime_family")
    assert_equal "1.21.4", visible_server.fetch("minecraft_version")
    assert_equal "1.21.4", visible_server.fetch("resolved_minecraft_version")
    assert_equal "1.21.4", visible_server.fetch("minecraft_version_display")
    assert_equal users(:one).discord_global_name, visible_server.fetch("owner_display_name")
    assert_equal "viewer", visible_server.fetch("access_role")
    assert_equal "success", visible_server.fetch("route").fetch("last_apply_status")
    assert_equal "healthy", visible_server.fetch("route").fetch("last_healthcheck_status")
    assert_equal true, visible_server.fetch("route").fetch("enabled")
    assert_equal "mc-server-main-survival", visible_server.fetch("runtime").fetch("container_name")
    assert_equal "container-001", visible_server.fetch("runtime").fetch("container_id")
    assert_equal "running", visible_server.fetch("runtime").fetch("container_state")
    assert_equal "mc-data-main-survival", visible_server.fetch("runtime").fetch("volume_name")
    assert_not visible_server.fetch("runtime").key?("backend")
  end

  test "index falls back to a fixed owner display label when discord names are missing" do
    owner = users(:one)
    owner.update!(discord_global_name: nil, discord_username: nil)
    sign_in_as(users(:two))

    get servers_url(format: :json)

    assert_response :success

    visible_server = response.parsed_body.fetch("servers").detect { |server| server.fetch("id") == minecraft_servers(:one).id }

    assert_equal "未設定ユーザー", visible_server.fetch("owner_display_name")
  end

  test "show allows visible server for member" do
    minecraft_servers(:one).update!(last_error_message: "runtime unavailable")
    sign_in_as(users(:three))

    get server_url(minecraft_servers(:one), format: :json)

    assert_response :success
    server = response.parsed_body.fetch("server")

    assert_equal minecraft_servers(:one).id, server.fetch("id")
    assert_equal "manager", server.fetch("access_role")
    assert_equal "1.21.4", server.fetch("minecraft_version_display")
    assert_equal "runtime unavailable", server.fetch("last_error_message")
    assert_equal users(:one).discord_global_name, server.fetch("owner_display_name")
    assert_kind_of Integer, server.fetch("uptime_seconds")
    assert_equal true, server.fetch("can_stop")
    assert_equal true, server.fetch("can_restart")
    assert_equal true, server.fetch("can_sync")
    assert_equal false, server.fetch("can_start")
    assert_equal false, server.fetch("can_destroy")
  end

  test "show exposes start and sync for stopped servers" do
    server = minecraft_servers(:one)
    server.update_columns(status: MinecraftServer.statuses.fetch(:stopped), container_state: "exited")
    sign_in_as(users(:three))

    get server_url(server, format: :json)

    assert_response :success
    payload = response.parsed_body.fetch("server")

    assert_equal true, payload.fetch("can_start")
    assert_equal false, payload.fetch("can_stop")
    assert_equal false, payload.fetch("can_restart")
    assert_equal true, payload.fetch("can_sync")
    assert_nil payload.fetch("uptime_seconds")
  end

  test "show exposes only sync during transitional statuses" do
    server = minecraft_servers(:one)
    server.update_columns(status: MinecraftServer.statuses.fetch(:starting), container_state: "running")
    sign_in_as(users(:three))

    get server_url(server, format: :json)

    assert_response :success
    payload = response.parsed_body.fetch("server")

    assert_equal false, payload.fetch("can_start")
    assert_equal false, payload.fetch("can_stop")
    assert_equal false, payload.fetch("can_restart")
    assert_equal true, payload.fetch("can_sync")
  end

  test "show exposes only sync for degraded servers" do
    server = minecraft_servers(:one)
    server.update_columns(status: MinecraftServer.statuses.fetch(:degraded), container_state: "unknown")
    sign_in_as(users(:three))

    get server_url(server, format: :json)

    assert_response :success
    payload = response.parsed_body.fetch("server")

    assert_equal false, payload.fetch("can_start")
    assert_equal false, payload.fetch("can_stop")
    assert_equal false, payload.fetch("can_restart")
    assert_equal true, payload.fetch("can_sync")
  end

  test "show returns not found for invisible server" do
    sign_in_as(users(:three))

    get server_url(minecraft_servers(:two), format: :json)

    assert_response :not_found
  end

  test "reader cannot open new server page" do
    sign_in_as(users(:three))

    get new_server_url(format: :json)

    assert_response :forbidden
  end

  test "operator can open new server page" do
    sign_in_as(users(:two))

    get new_server_url(format: :json)

    assert_response :success
  end

  test "show hides lifecycle controls when container id is missing" do
    server = minecraft_servers(:one)
    server.update_columns(container_id: nil)
    sign_in_as(users(:one))

    get server_url(server, format: :json)

    assert_response :success
    payload = response.parsed_body.fetch("server")

    assert_equal false, payload.fetch("can_start")
    assert_equal false, payload.fetch("can_stop")
    assert_equal false, payload.fetch("can_restart")
    assert_equal false, payload.fetch("can_sync")
  end

  test "create stores a provisional server and enqueues provisioning job" do
    sign_in_as(users(:one))

    assert_difference("MinecraftServer.count", 1) do
      assert_difference("RouterRoute.count", 1) do
        assert_enqueued_jobs 1, only: CreateServerJob do
          post servers_url, params: {
            minecraft_server: {
              name: "Creative Build",
              hostname: "Creative-Build",
              runtime_family: "paper",
              minecraft_version: "1.21.4",
              memory_mb: 4096,
              disk_mb: 40960,
            },
          }
        end
      end
    end

    server = MinecraftServer.order(:id).last

    assert_redirected_to server_path(server)
    assert_equal users(:one).id, server.owner_id
    assert_equal "creative-build", server.hostname
    assert_equal "provisioning", server.status
    assert_equal "mc-server-creative-build", server.container_name
    assert_equal "mc-data-creative-build", server.volume_name
    assert_nil server.container_id
    assert_nil server.container_state
    assert_equal "paper", server.template_kind
    assert_equal false, server.router_route.enabled
    assert_equal "unpublished", server.router_route.publication_state
    assert_equal "pending", server.router_route.last_apply_status
    assert_equal "unknown", server.router_route.last_healthcheck_status
  end

  test "new exposes operator memory quota summary" do
    sign_in_as(users(:two))

    get new_server_url(format: :json)

    assert_response :success
    quota = response.parsed_body.fetch("create_quota")
    assert_equal true, quota.fetch("applies")
    assert_equal 5120, quota.fetch("limit_mb")
    assert_equal 4096, quota.fetch("used_mb")
    assert_equal 1024, quota.fetch("remaining_mb")
  end

  test "create rejects operator request above memory quota" do
    sign_in_as(users(:two))

    assert_no_difference("MinecraftServer.count") do
      post servers_url(format: :json), params: {
        minecraft_server: {
          name: "Quota Breaker",
          hostname: "quota-breaker",
          runtime_family: "paper",
          minecraft_version: "1.21.4",
          memory_mb: 3584,
          disk_mb: 20480,
        },
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.fetch("errors").fetch("memory_mb"), "Memory mb は上限 5120 MB を超えます。残りは 1024 MB です。"
  end

  test "reader cannot create a server" do
    sign_in_as(users(:three))

    assert_no_difference("MinecraftServer.count") do
      post servers_url(format: :json), params: {
        minecraft_server: {
          name: "Reader Blocked",
          hostname: "reader-blocked",
          runtime_family: "paper",
          minecraft_version: "1.21.4",
          memory_mb: 1024,
          disk_mb: 20480,
        },
      }
    end

    assert_response :forbidden
  end

  test "create returns validation errors without storing a server" do
    sign_in_as(users(:one))

    assert_no_difference("MinecraftServer.count") do
      assert_no_difference("RouterRoute.count") do
        post servers_url(format: :json), params: {
          minecraft_server: {
            name: "",
            hostname: "bad host",
            runtime_family: "paper",
            minecraft_version: "1.21.4",
            memory_mb: 0,
            disk_mb: 0,
          },
        }
      end
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.fetch("errors").keys, "name"
    assert_includes response.parsed_body.fetch("errors").keys, "hostname"
    assert_includes response.parsed_body.fetch("errors").keys, "memory_mb"
  end

  test "owner can delete a server" do
    sign_in_as(users(:one))
    server = minecraft_servers(:one)
    original_new = Servers::DestroyServer.method(:new)
    fake_service = Object.new
    fake_service.define_singleton_method(:call) do
      server.destroy!
    end

    Servers::DestroyServer.define_singleton_method(:new) do |*|
      fake_service
    end

    assert_difference("MinecraftServer.count", -1) do
      assert_difference("RouterRoute.count", -1) do
        delete server_url(server, format: :json)
      end
    end

    assert_response :no_content
    assert_not MinecraftServer.exists?(server.id)
  ensure
    Servers::DestroyServer.define_singleton_method(:new, original_new)
  end

  test "non-owner cannot delete a visible server" do
    sign_in_as(users(:three))

    assert_no_difference("MinecraftServer.count") do
      assert_no_difference("RouterRoute.count") do
        delete server_url(minecraft_servers(:one), format: :json)
      end
    end

    assert_response :forbidden
  end

  test "manager membership can start a visible server" do
    sign_in_as(users(:three))
    server = minecraft_servers(:one)
    original_new = Servers::StartServer.method(:new)
    fake_service = Object.new
    fake_service.define_singleton_method(:call) do
      server.update!(status: :starting)
    end

    Servers::StartServer.define_singleton_method(:new) do |*|
      fake_service
    end

    post start_server_url(server, format: :json)

    assert_response :success
    assert_equal "starting", response.parsed_body.fetch("server").fetch("status")
  ensure
    Servers::StartServer.define_singleton_method(:new, original_new)
  end

  test "viewer cannot stop a server" do
    sign_in_as(users(:two))

    post stop_server_url(minecraft_servers(:one), format: :json)

    assert_response :forbidden
  end

  test "owner can sync a server state" do
    sign_in_as(users(:one))
    server = minecraft_servers(:one)
    original_new = Servers::SyncServerState.method(:new)
    fake_service = Object.new
    fake_service.define_singleton_method(:call) do
      server.update!(status: :degraded)
    end

    Servers::SyncServerState.define_singleton_method(:new) do |*|
      fake_service
    end

    post sync_server_url(server, format: :json)

    assert_response :success
    assert_equal "degraded", response.parsed_body.fetch("server").fetch("status")
  ensure
    Servers::SyncServerState.define_singleton_method(:new, original_new)
  end
end
