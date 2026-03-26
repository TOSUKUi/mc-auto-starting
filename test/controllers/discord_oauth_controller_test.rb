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
