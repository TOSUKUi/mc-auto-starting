require "test_helper"

class DiscordOauthControllerTest < ActionDispatch::IntegrationTest
  test "callback signs in an existing discord user" do
    get "/auth/discord/callback", headers: omniauth_headers_for(users(:one))

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal users(:one).discord_user_id, users(:one).reload.discord_user_id
  end

  test "callback rejects an unknown discord user" do
    get "/auth/discord/callback", headers: {
      "omniauth.auth" => {
        "provider" => "discord",
        "uid" => "999999999999999999",
        "info" => { "name" => "new-user", "email" => "new@example.com" },
      },
    }

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
    assert_redirected_to "/auth/discord"

    assert_difference("User.count", 1) do
      get "/auth/discord/callback", headers: {
        "omniauth.auth" => {
          "provider" => "discord",
          "uid" => invitation.discord_user_id,
          "info" => {
            "name" => "fresh-user",
            "global_name" => "Fresh User",
            "email" => "fresh@example.com",
            "image" => "https://cdn.discordapp.test/fresh-avatar.png",
          },
        },
      }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal invitation.discord_user_id, User.order(:id).last.discord_user_id
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
    assert_redirected_to "/auth/discord"

    assert_no_difference("User.count") do
      get "/auth/discord/callback", headers: {
        "omniauth.auth" => {
          "provider" => "discord",
          "uid" => "999999999999999999",
          "info" => {
            "name" => "wrong-user",
            "email" => "wrong@example.com",
          },
        },
      }
    end

    assert_redirected_to login_path
    assert_nil invitation.reload.used_at
  end

  private
    def omniauth_headers_for(user)
      {
        "omniauth.auth" => {
          "provider" => "discord",
          "uid" => user.discord_user_id,
          "info" => {
            "name" => "#{user.discord_username}-updated",
            "global_name" => "#{user.discord_global_name} Updated",
            "email" => user.email_address,
            "image" => "https://cdn.discordapp.test/avatar.png",
          },
        },
      }
    end
end
