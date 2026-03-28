require "test_helper"

class MinecraftServerPolicyTest < ActiveSupport::TestCase
  test "create is allowed for admin and operator but denied for reader" do
    assert MinecraftServerPolicy.new(users(:one), MinecraftServer).create?
    assert MinecraftServerPolicy.new(users(:two), MinecraftServer).create?
    assert_not MinecraftServerPolicy.new(users(:three), MinecraftServer).create?
  end

  test "owner can manage and operate the server" do
    policy = MinecraftServerPolicy.new(users(:one), minecraft_servers(:one))

    assert policy.show?
    assert policy.update?
    assert policy.destroy?
    assert policy.manage_members?
    assert policy.manage_whitelist?
    assert policy.start?
    assert policy.stop?
    assert policy.restart?
    assert policy.sync?
  end

  test "admin can view operate destroy and manage a non-owned server" do
    server = minecraft_servers(:two)
    server.update_columns(container_id: "container-002", container_state: "running", status: "ready")
    policy = MinecraftServerPolicy.new(users(:one), server)

    assert policy.show?
    assert policy.destroy?
    assert policy.manage_members?
    assert policy.manage_whitelist?
  end

  test "manager membership can view and operate but not manage ownership actions" do
    policy = MinecraftServerPolicy.new(users(:three), minecraft_servers(:one))

    assert policy.show?
    assert policy.start?
    assert policy.stop?
    assert policy.restart?
    assert policy.sync?
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.manage_members?
    assert_not policy.manage_whitelist?
  end

  test "viewer membership can only read the server" do
    policy = MinecraftServerPolicy.new(users(:two), minecraft_servers(:one))

    assert policy.show?
    assert_not policy.start?
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.manage_members?
    assert_not policy.manage_whitelist?
  end

  test "non-member cannot view the server" do
    policy = MinecraftServerPolicy.new(users(:three), minecraft_servers(:two))

    assert_not policy.show?
    assert_not policy.start?
  end

  test "scope includes owned and member servers only" do
    visible_servers = MinecraftServerPolicy::Scope.new(users(:two), MinecraftServer).resolve.order(:id).to_a

    assert_equal [ minecraft_servers(:two), minecraft_servers(:one) ], visible_servers
  end

  test "scope includes all servers for admin" do
    visible_servers = MinecraftServerPolicy::Scope.new(users(:one), MinecraftServer).resolve.order(:id).to_a

    assert_equal [ minecraft_servers(:two), minecraft_servers(:one) ], visible_servers
  end

  test "scope is empty for anonymous users" do
    assert_empty MinecraftServerPolicy::Scope.new(nil, MinecraftServer).resolve
  end

  test "lifecycle actions are blocked when the container id is missing" do
    server = minecraft_servers(:one)
    server.update_columns(container_id: nil)

    policy = MinecraftServerPolicy.new(users(:one), server)

    assert_not policy.start?
    assert_not policy.stop?
    assert_not policy.restart?
    assert_not policy.sync?
    assert_not policy.manage_whitelist?
  end
end
