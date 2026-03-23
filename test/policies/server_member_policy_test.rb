require "test_helper"

class ServerMemberPolicyTest < ActiveSupport::TestCase
  test "server owner can manage memberships" do
    policy = ServerMemberPolicy.new(users(:one), server_members(:one))

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "non-owner cannot manage memberships" do
    policy = ServerMemberPolicy.new(users(:two), server_members(:one))

    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "scope returns only memberships on owned servers" do
    visible_memberships = ServerMemberPolicy::Scope.new(users(:one), ServerMember).resolve.order(:id).to_a

    assert_equal [ server_members(:two), server_members(:one) ], visible_memberships
  end

  test "scope is empty for non-owners without owned servers" do
    assert_empty ServerMemberPolicy::Scope.new(users(:three), ServerMember).resolve
  end
end
