require "test_helper"

class DiscordInvitationTest < ActiveSupport::TestCase
  test "issue! stores only token digest" do
    invitation, raw_token = DiscordInvitation.issue!(
      invited_by: users(:one),
      discord_user_id: "777777777777777777",
      expires_at: 3.days.from_now,
      note: "manual issue",
    )

    assert invitation.persisted?
    assert_equal "777777777777777777", invitation.discord_user_id
    assert_equal "manual issue", invitation.note
    assert_not_equal raw_token, invitation.token_digest
    assert_equal DiscordInvitation.digest_token(raw_token), invitation.token_digest
  end

  test "status reflects active expired and revoked states" do
    assert_equal "active", discord_invitations(:one).status
    assert_equal "expired", discord_invitations(:two).status
    assert_equal "revoked", discord_invitations(:three).status
  end

  test "rejects non numeric discord user id" do
    invitation = DiscordInvitation.new(
      invited_by: users(:one),
      discord_user_id: "discord-user",
      expires_at: 1.day.from_now,
      token_digest: "digest",
    )

    assert_not invitation.valid?
    assert_includes invitation.errors[:discord_user_id], "must be a Discord user ID"
  end
end
