require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  test "belongs to minecraft_server" do
    log = audit_logs(:one)

    assert_equal minecraft_servers(:one), log.minecraft_server
  end

  test "allows actor to be nil for system events" do
    log = audit_logs(:two)

    assert_nil log.actor
    assert log.valid?
  end

  test "requires event_type" do
    log = AuditLog.new(minecraft_server: minecraft_servers(:one), payload: {})

    assert_not log.valid?
    assert_includes log.errors[:event_type], "can't be blank"
  end

  test "strips event_type before validation" do
    log = AuditLog.new(
      minecraft_server: minecraft_servers(:one),
      actor: users(:one),
      event_type: "  server.started  ",
      payload: { "source" => "test" }
    )

    assert log.valid?
    assert_equal "server.started", log.event_type
  end

  test "defaults payload to empty hash" do
    log = AuditLog.new(
      minecraft_server: minecraft_servers(:one),
      actor: users(:one),
      event_type: "server.started"
    )

    assert log.valid?
    assert_equal({}, log.payload)
  end

  test "orders recent logs first" do
    older = AuditLog.create!(
      minecraft_server: minecraft_servers(:one),
      actor: users(:one),
      event_type: "server.stopped",
      payload: { "sequence" => "older" }
    )
    newer = AuditLog.create!(
      minecraft_server: minecraft_servers(:one),
      event_type: "server.started",
      payload: { "sequence" => "newer" }
    )

    older.update_column(:created_at, 5.minutes.ago)
    newer.update_column(:created_at, Time.current)

    assert_equal [ newer, older ], AuditLog.where(id: [ older.id, newer.id ]).recent_first.to_a
  end
end
