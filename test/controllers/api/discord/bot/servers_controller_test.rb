require "test_helper"

class Api::Discord::Bot::ServersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_token = Rails.application.config.x.discord_bot.api_token
    @original_cidrs = Rails.application.config.x.discord_bot.allowed_cidrs
    Rails.application.config.x.discord_bot.api_token = "discord-bot-token"
    Rails.application.config.x.discord_bot.allowed_cidrs = [ "172.16.0.0/12" ]
    @original_whitelist_new = Servers::WhitelistManager.method(:new)
    @original_rcon_execute = Servers::BoundedRconCommand.instance_method(:execute)
  end

  teardown do
    Rails.application.config.x.discord_bot.api_token = @original_token
    Rails.application.config.x.discord_bot.allowed_cidrs = @original_cidrs
    Servers::WhitelistManager.define_singleton_method(:new, @original_whitelist_new)
    Servers::BoundedRconCommand.define_method(:execute, @original_rcon_execute)
  end

  test "rejects missing bot token" do
    post status_api_discord_bot_server_url(minecraft_servers(:one)),
      headers: bot_headers(token: nil, discord_user_id: users(:one).discord_user_id),
      env: bot_env

    assert_response :unauthorized
    assert_equal "unauthorized_bot", response.parsed_body.fetch("error_code")
  end

  test "rejects requests from outside the private bot network" do
    post status_api_discord_bot_server_url(minecraft_servers(:one)),
      headers: bot_headers(discord_user_id: users(:one).discord_user_id),
      env: bot_env(remote_addr: "203.0.113.10")

    assert_response :not_found
  end

  test "reader can read server status through bot api" do
    post status_api_discord_bot_server_url(minecraft_servers(:one)),
      headers: bot_headers(discord_user_id: users(:three).discord_user_id),
      env: bot_env

    assert_response :success
    assert_equal true, response.parsed_body.fetch("ok")
    assert_equal "status", response.parsed_body.fetch("action")
  end

  test "manager can restart through bot api" do
    fake_client = Struct.new(:calls, keyword_init: true) do
      def stop_container(**kwargs) = calls << [ :stop_container, kwargs ]
      def remove_container(**kwargs) = calls << [ :remove_container, kwargs ]
      def create_container(**kwargs) = calls << [ :create_container, kwargs ] && { "Id" => "container-222" }
      def start_container(**kwargs) = calls << [ :start_container, kwargs ]
      def inspect_container(**kwargs) = calls << [ :inspect_container, kwargs ] && { "Id" => "container-222", "State" => { "Status" => "running" } }
      def pull_image(**) = true
    end.new(calls: [])

    original_new = Servers::RestartServer.method(:new)
    Servers::RestartServer.define_singleton_method(:new) do |*args, **kwargs|
      original_new.call(*args, **kwargs.merge(docker_client: fake_client))
    end

    post restart_api_discord_bot_server_url(minecraft_servers(:one)),
      headers: bot_headers(discord_user_id: users(:three).discord_user_id),
      env: bot_env

    assert_response :success
    assert_equal "restart", response.parsed_body.fetch("action")
  ensure
    Servers::RestartServer.define_singleton_method(:new, original_new) if original_new
  end

  test "reader cannot restart through bot api" do
    post restart_api_discord_bot_server_url(minecraft_servers(:two)),
      headers: bot_headers(discord_user_id: users(:two).discord_user_id),
      env: bot_env

    assert_response :forbidden
  end

  test "owner can mutate whitelist through bot api" do
    server = minecraft_servers(:one)
    server.update_columns(container_state: "running", status: "ready")
    stub_whitelist_manager

    post whitelist_add_api_discord_bot_server_url(server),
      headers: bot_headers(discord_user_id: users(:one).discord_user_id),
      env: bot_env,
      params: { player_name: "Steve" }

    assert_response :success
    assert_equal [ "Steve" ], server.reload.whitelist_entries
  end

  test "reader can view whitelist list through bot api" do
    server = minecraft_servers(:one)
    server.update!(whitelist_entries: [ "Steve" ])

    post whitelist_list_api_discord_bot_server_url(server),
      headers: bot_headers(discord_user_id: users(:two).discord_user_id),
      env: bot_env

    assert_response :success
    assert_equal [ "Steve" ], response.parsed_body.fetch("result").fetch("entries")
  end

  test "owner can run bounded rcon command through bot api" do
    Servers::BoundedRconCommand.define_method(:execute) { |command:| "Executed: #{command}" }

    post rcon_command_api_discord_bot_server_url(minecraft_servers(:one)),
      headers: bot_headers(discord_user_id: users(:one).discord_user_id),
      env: bot_env,
      params: { command: "say hello" }

    assert_response :success
    assert_equal "Executed: say hello", response.parsed_body.fetch("result").fetch("response_body")
  end

  test "manager cannot run bounded rcon command through bot api" do
    post rcon_command_api_discord_bot_server_url(minecraft_servers(:one)),
      headers: bot_headers(discord_user_id: users(:three).discord_user_id),
      env: bot_env,
      params: { command: "say hello" }

    assert_response :forbidden
  end

  test "forbidden bounded rcon command returns validation error" do
    post rcon_command_api_discord_bot_server_url(minecraft_servers(:one)),
      headers: bot_headers(discord_user_id: users(:one).discord_user_id),
      env: bot_env,
      params: { command: "stop" }

    assert_response :unprocessable_entity
    assert_equal "rcon_command_forbidden", response.parsed_body.fetch("error_code")
  end

  private
    def bot_headers(discord_user_id:, token: "discord-bot-token")
      headers = {
        "X-Discord-User-Id" => discord_user_id,
      }
      headers["Authorization"] = "Bearer #{token}" if token
      headers
    end

    def bot_env(remote_addr: "172.18.0.10")
      { "REMOTE_ADDR" => remote_addr }
    end

    def stub_whitelist_manager
      manager = Struct.new(:calls) do
        def add_player!(player_name) = calls << [ :add, player_name ]
        def remove_player!(player_name) = calls << [ :remove, player_name ]
        def enable! = calls << [ :enable ]
        def disable! = calls << [ :disable ]
        def reload! = calls << [ :reload ]
      end.new([])

      Servers::WhitelistManager.define_singleton_method(:new) do |*|
        manager
      end
    end
end
