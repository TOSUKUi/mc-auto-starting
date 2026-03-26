require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  test "valid invite stores pending token and redirects to discord auth" do
    invitation, raw_token = DiscordInvitation.issue!(
      invited_by: users(:one),
      discord_user_id: "777777777777777777",
      expires_at: 7.days.from_now,
      note: "test invite",
    )

    get invite_url(raw_token)

    assert_redirected_to "/auth/discord"

    get "/auth/discord/callback", headers: {
      "omniauth.auth" => {
        "provider" => "discord",
        "uid" => invitation.discord_user_id,
        "info" => {
          "name" => "invited-user",
          "global_name" => "Invited User",
          "email" => "invited@example.com",
          "image" => "https://cdn.discordapp.test/new-avatar.png",
        },
      },
    }

    assert_redirected_to root_path
    assert_equal invitation.discord_user_id, User.order(:id).last.discord_user_id
    assert invitation.reload.used_at.present?
  end

  test "invalid invite redirects back to login" do
    get invite_url("missing-token")

    assert_redirected_to login_path
  end
end
