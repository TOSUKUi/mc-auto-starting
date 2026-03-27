require "test_helper"

class ServerMemberTest < ActiveSupport::TestCase
  test "belongs to server and user" do
    membership = server_members(:one)

    assert_equal minecraft_servers(:one), membership.minecraft_server
    assert_equal users(:two), membership.user
  end

  test "defines allowed roles" do
    assert ServerMember.roles.key?("viewer")
    assert ServerMember.roles.key?("manager")
  end

  test "rejects duplicate membership for the same server" do
    membership = ServerMember.new(minecraft_server: minecraft_servers(:one), user: users(:two), role: :manager)

    assert_not membership.valid?
    assert_includes membership.errors[:user_id], "has already been taken"
  end

  test "rejects duplicating the owner as a member" do
    membership = ServerMember.new(minecraft_server: minecraft_servers(:one), user: users(:one), role: :viewer)

    assert_not membership.valid?
    assert_includes membership.errors[:user_id], "cannot duplicate the server owner"
  end
end
