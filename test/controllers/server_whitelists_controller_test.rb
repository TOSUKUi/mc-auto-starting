require "test_helper"

class ServerWhitelistsControllerTest < ActionDispatch::IntegrationTest
  FakeWhitelistManager = Struct.new(:entries, :calls, :error, keyword_init: true) do
    def list_entries
      calls << [ :list_entries ]
      raise error if error

      entries
    end

    def enable!
      calls << [ :enable ]
      raise error if error
    end

    def disable!
      calls << [ :disable ]
      raise error if error
    end

    def reload!
      calls << [ :reload ]
      raise error if error
    end

    def add_player!(player_name)
      calls << [ :add, player_name ]
      raise error if error
    end

    def remove_player!(player_name)
      calls << [ :remove, player_name ]
      raise error if error
    end
  end

  setup do
    @original_new = Servers::WhitelistManager.method(:new)
  end

  teardown do
    Servers::WhitelistManager.define_singleton_method(:new, @original_new)
  end

  test "owner can fetch whitelist entries" do
    minecraft_servers(:one).update!(whitelist_entries: [ "Alex", "Steve" ], whitelist_enabled: true)
    manager = stub_whitelist_manager(entries: [ "Alex", "Steve" ])
    sign_in_as(users(:one))

    get whitelist_server_url(minecraft_servers(:one), format: :json)

    assert_response :success
    assert_equal [ "Alex", "Steve" ], response.parsed_body.fetch("whitelist").fetch("entries")
    assert_equal true, response.parsed_body.fetch("whitelist").fetch("enabled")
    assert_equal false, response.parsed_body.fetch("whitelist").fetch("staged_only")
    assert_empty manager.calls
  end

  test "admin can manage whitelist for a non-owned visible server" do
    server = minecraft_servers(:two)
    server.update_columns(container_id: "container-002", container_state: "running", status: "ready")
    manager = stub_whitelist_manager(entries: [ "Alex" ])
    sign_in_as(users(:one))

    post add_whitelist_player_server_url(server, format: :json), params: { player_name: "Alex" }

    assert_response :success
    assert_equal [ [ :add, "Alex" ] ], manager.calls
    assert_equal [ "Alex" ], server.reload.whitelist_entries
  end

  test "manager membership cannot fetch whitelist entries" do
    sign_in_as(users(:three))

    get whitelist_server_url(minecraft_servers(:one), format: :json)

    assert_response :forbidden
  end

  test "viewer membership cannot mutate whitelist entries" do
    sign_in_as(users(:two))

    post add_whitelist_player_server_url(minecraft_servers(:one), format: :json), params: { player_name: "Steve" }

    assert_response :forbidden
  end

  test "stopped server whitelist action is staged for next start" do
    minecraft_servers(:one).update_columns(container_state: "exited", status: "stopped")
    manager = stub_whitelist_manager(entries: [])
    sign_in_as(users(:one))

    post add_whitelist_player_server_url(minecraft_servers(:one), format: :json), params: { player_name: "Steve" }

    assert_response :success
    assert_equal [ "Steve" ], response.parsed_body.fetch("whitelist").fetch("entries")
    assert_equal true, response.parsed_body.fetch("whitelist").fetch("staged_only")
    assert_empty manager.calls
  end

  test "rcon command failure returns unprocessable entity" do
    manager = stub_whitelist_manager(error: MinecraftRcon::CommandError.new("invalid player name"))
    sign_in_as(users(:one))

    delete remove_whitelist_player_server_url(minecraft_servers(:one), format: :json), params: { player_name: "bad name" }

    assert_response :unprocessable_entity
    assert_equal "invalid player name", response.parsed_body.fetch("error")
    assert_equal [ [ :remove, "bad name" ] ], manager.calls
  end

  private
    def stub_whitelist_manager(entries: [], error: nil)
      manager = FakeWhitelistManager.new(entries: entries, calls: [], error: error)

      Servers::WhitelistManager.define_singleton_method(:new) do |*|
        manager
      end

      manager
    end
end
