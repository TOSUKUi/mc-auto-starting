require "test_helper"

class MinecraftServerTest < ActiveSupport::TestCase
  test "belongs to owner" do
    server = minecraft_servers(:one)

    assert_equal users(:one), server.owner
  end

  test "defines known statuses" do
    assert MinecraftServer.statuses.key?("provisioning")
    assert MinecraftServer.statuses.key?("ready")
    assert MinecraftServer.statuses.key?("failed")
  end

  test "defines allowed status transitions" do
    assert_includes MinecraftServer::STATUS_TRANSITIONS[:provisioning], :ready
    assert_includes MinecraftServer::STATUS_TRANSITIONS[:ready], :restarting
    assert_includes MinecraftServer::STATUS_TRANSITIONS[:degraded], :unpublished
  end

  test "requires core provisioning attributes" do
    server = MinecraftServer.new(owner: users(:one))

    assert_not server.valid?
    assert_includes server.errors[:name], "can't be blank"
    assert_includes server.errors[:hostname], "can't be blank"
    assert_includes server.errors[:provider_name], "can't be blank"
    assert_includes server.errors[:minecraft_version], "can't be blank"
    assert_includes server.errors[:template_kind], "can't be blank"
  end

  test "normalizes hostname before validation" do
    server = minecraft_servers(:one)
    server.hostname = "  Mixed-Case-Host  "
    server.valid?

    assert_equal "mixed-case-host", server.hostname
  end

  test "rejects invalid hostname format" do
    server = minecraft_servers(:one)
    server.hostname = "-bad-host-"

    assert_not server.valid?
    assert_includes server.errors[:hostname], "must use lowercase letters, numbers, and internal hyphens only"
  end

  test "rejects reserved hostname" do
    server = minecraft_servers(:one)
    server.hostname = "admin"

    assert_not server.valid?
    assert_includes server.errors[:hostname], "is reserved"
  end

  test "rejects duplicate hostname after normalization" do
    server = minecraft_servers(:two)
    server.hostname = "  MAIN-SURVIVAL  "

    assert_not server.valid?
    assert_includes server.errors[:hostname], "has already been taken"
  end

  test "builds fqdn from hostname and shared public domain" do
    server = minecraft_servers(:one)

    assert_equal "main-survival.mc.tosukui.xyz", server.fqdn
  end

  test "builds connection target from fqdn and shared public port" do
    server = minecraft_servers(:one)

    assert_equal "main-survival.mc.tosukui.xyz:42434", server.connection_target
  end

  test "allows valid status transitions" do
    server = minecraft_servers(:one)
    server.status = :restarting

    assert server.valid?
  end

  test "rejects invalid status transitions" do
    server = minecraft_servers(:one)
    server.status = :provisioning

    assert_not server.valid?
    assert_includes server.errors[:status], "cannot transition from ready to provisioning"
  end

  test "transition_to! persists a valid transition" do
    server = minecraft_servers(:two)

    server.transition_to!(:ready)

    assert_equal "ready", server.reload.status
  end

  test "transition_to! raises for an invalid transition" do
    server = minecraft_servers(:one)

    error = assert_raises(ArgumentError) { server.transition_to!(:provisioning) }

    assert_equal "invalid status transition: ready -> provisioning", error.message
  end

  test "validates numeric resource fields" do
    server = minecraft_servers(:one)
    server.memory_mb = 0
    server.disk_mb = -1
    server.backend_port = 70_000

    assert_not server.valid?
    assert_includes server.errors[:memory_mb], "must be greater than 0"
    assert_includes server.errors[:disk_mb], "must be greater than 0"
    assert_includes server.errors[:backend_port], "must be less than or equal to 65535"
  end
end
