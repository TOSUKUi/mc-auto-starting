require "test_helper"

class DiscordInvitationPolicyTest < ActiveSupport::TestCase
  test "admin can list and create invitations" do
    policy = DiscordInvitationPolicy.new(users(:one), DiscordInvitation)

    assert policy.index?
    assert policy.create?
  end

  test "operator can list and create invitations" do
    policy = DiscordInvitationPolicy.new(users(:two), DiscordInvitation)

    assert policy.index?
    assert policy.create?
  end

  test "reader cannot list or create invitations" do
    policy = DiscordInvitationPolicy.new(users(:three), DiscordInvitation)

    assert_not policy.index?
    assert_not policy.create?
  end

  test "issuer can revoke their own invitation" do
    policy = DiscordInvitationPolicy.new(users(:one), discord_invitations(:one))

    assert policy.revoke?
  end

  test "non issuer cannot revoke invitation" do
    policy = DiscordInvitationPolicy.new(users(:one), discord_invitations(:three))

    assert_not policy.revoke?
  end
end
