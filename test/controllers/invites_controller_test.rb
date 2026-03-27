require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  test "valid invite stores pending token and redirects to discord auth" do
    invitation, raw_token = DiscordInvitation.issue!(
      invited_by: users(:one),
      discord_user_id: "777777777777777777",
      invited_user_type: "reader",
      expires_at: 7.days.from_now,
      note: "test invite",
    )

    get invite_url(raw_token)

    assert_redirected_to discord_login_path

    with_mocked_discord_auth(
      uid: invitation.discord_user_id,
      info: {
        "name" => "invited-user",
        "global_name" => "Invited User",
        "image" => "https://cdn.discordapp.test/new-avatar.png",
      },
    ) do
      get "/auth/discord/callback"
    end

    assert_redirected_to root_path
    user = User.order(:id).last
    assert_equal invitation.discord_user_id, user.discord_user_id
    assert_equal "reader", user.user_type
    assert_nil user.email_address
    assert invitation.reload.used_at.present?
  end

  test "invalid invite redirects back to login" do
    get invite_url("missing-token")

    assert_redirected_to login_path
  end

  private
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
