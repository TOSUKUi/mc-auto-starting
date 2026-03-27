require "test_helper"

class DiscordOauthControllerTest < ActionDispatch::IntegrationTest
  test "start redirects to discord oauth when configured" do
    with_discord_oauth_env do
      get discord_login_path

      assert_redirected_to "/auth/discord"
    end
  end

  test "start returns to login when oauth is not configured" do
    without_discord_oauth_env do
      get discord_login_path
    end

    assert_redirected_to login_path
  end

  test "callback signs in an existing discord user" do
    with_mocked_discord_auth_for(users(:one)) do
      get "/auth/discord/callback"
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal users(:one).discord_user_id, users(:one).reload.discord_user_id
  end

  test "callback rejects an unknown discord user" do
    with_mocked_discord_auth(
      uid: "999999999999999999",
      info: { "name" => "new-user" },
    ) do
      get "/auth/discord/callback"
    end

    assert_redirected_to login_path
    assert_nil cookies[:session_id]
  end

  test "callback creates a new user when a matching invite is pending" do
    invitation, raw_token = DiscordInvitation.issue!(
      invited_by: users(:one),
      discord_user_id: "999999999999999999",
      expires_at: 7.days.from_now,
      note: "callback invite",
    )

    get invite_url(raw_token)
    assert_redirected_to discord_login_path

    assert_difference("User.count", 1) do
      with_mocked_discord_auth(
        uid: invitation.discord_user_id,
        info: {
          "name" => "fresh-user",
          "global_name" => "Fresh User",
          "image" => "https://cdn.discordapp.test/fresh-avatar.png",
        },
      ) do
        get "/auth/discord/callback"
      end
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
    user = User.order(:id).last
    assert_equal invitation.discord_user_id, user.discord_user_id
    assert_nil user.email_address
    assert invitation.reload.used_at.present?
  end

  test "callback rejects invite when discord user id does not match pending invite" do
    invitation, raw_token = DiscordInvitation.issue!(
      invited_by: users(:one),
      discord_user_id: "999999999999999998",
      expires_at: 7.days.from_now,
      note: "mismatch invite",
    )

    get invite_url(raw_token)
    assert_redirected_to discord_login_path

    assert_no_difference("User.count") do
      with_mocked_discord_auth(
        uid: "999999999999999999",
        info: {
          "name" => "wrong-user",
        },
      ) do
        get "/auth/discord/callback"
      end
    end

    assert_redirected_to login_path
    assert_nil invitation.reload.used_at
  end

  private
    def with_discord_oauth_env
      original_client_id = ENV["DISCORD_CLIENT_ID"]
      original_client_secret = ENV["DISCORD_CLIENT_SECRET"]
      ENV["DISCORD_CLIENT_ID"] = "discord-client-id"
      ENV["DISCORD_CLIENT_SECRET"] = "discord-client-secret"
      yield
    ensure
      original_client_id.nil? ? ENV.delete("DISCORD_CLIENT_ID") : ENV["DISCORD_CLIENT_ID"] = original_client_id
      original_client_secret.nil? ? ENV.delete("DISCORD_CLIENT_SECRET") : ENV["DISCORD_CLIENT_SECRET"] = original_client_secret
    end

    def without_discord_oauth_env
      original_client_id = ENV["DISCORD_CLIENT_ID"]
      original_client_secret = ENV["DISCORD_CLIENT_SECRET"]
      ENV.delete("DISCORD_CLIENT_ID")
      ENV.delete("DISCORD_CLIENT_SECRET")
      yield
    ensure
      original_client_id.nil? ? ENV.delete("DISCORD_CLIENT_ID") : ENV["DISCORD_CLIENT_ID"] = original_client_id
      original_client_secret.nil? ? ENV.delete("DISCORD_CLIENT_SECRET") : ENV["DISCORD_CLIENT_SECRET"] = original_client_secret
    end

    def with_mocked_discord_auth_for(user, &block)
      with_mocked_discord_auth(
        uid: user.discord_user_id,
        info: {
          "name" => "#{user.discord_username}-updated",
          "global_name" => "#{user.discord_global_name} Updated",
          "image" => "https://cdn.discordapp.test/avatar.png",
        },
        &block
      )
    end

    def with_mocked_discord_auth(uid:, info:)
      original_test_mode = OmniAuth.config.test_mode
      original_mock = OmniAuth.config.mock_auth[:discord]

      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new(
        provider: "discord",
        uid: uid,
        info: info,
      )

      yield
    ensure
      OmniAuth.config.mock_auth[:discord] = original_mock
      OmniAuth.config.test_mode = original_test_mode
    end
end
