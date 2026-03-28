require "test_helper"

class Servers::WhitelistManagerTest < ActiveSupport::TestCase
  FakeConnection = Struct.new(:calls, :responses, keyword_init: true) do
    def execute(command, segmented: false)
      calls << [ command, segmented ]
      responses.fetch(command)
    end
  end

  test "list entries uses segmented whitelist list and parses player names" do
    server = minecraft_servers(:one)
    connection = FakeConnection.new(
      calls: [],
      responses: {
        "whitelist list" => "There are 2 whitelisted player(s): Steve, Alex",
      },
    )

    entries = Servers::WhitelistManager.new(server: server, connection: connection).list_entries

    assert_equal [ "Alex", "Steve" ], entries
    assert_equal [ [ "whitelist list", true ] ], connection.calls
  end

  test "enable disable and reload issue the expected commands" do
    server = minecraft_servers(:one)
    connection = FakeConnection.new(
      calls: [],
      responses: {
        "whitelist on" => "Whitelist is now enabled",
        "whitelist off" => "Whitelist is now disabled",
        "whitelist reload" => "Reloaded the whitelist",
      },
    )
    manager = Servers::WhitelistManager.new(server: server, connection: connection)

    manager.enable!
    manager.disable!
    manager.reload!

    assert_equal(
      [
        [ "whitelist on", false ],
        [ "whitelist off", false ],
        [ "whitelist reload", false ],
      ],
      connection.calls,
    )
  end

  test "add and remove validate the player name" do
    server = minecraft_servers(:one)
    connection = FakeConnection.new(
      calls: [],
      responses: {
        "whitelist add Steve_123" => "Added Steve_123",
        "whitelist remove Steve_123" => "Removed Steve_123",
      },
    )
    manager = Servers::WhitelistManager.new(server: server, connection: connection)

    manager.add_player!("Steve_123")
    manager.remove_player!("Steve_123")

    assert_equal(
      [
        [ "whitelist add Steve_123", false ],
        [ "whitelist remove Steve_123", false ],
      ],
      connection.calls,
    )
  end

  test "stopped servers cannot run whitelist commands" do
    server = minecraft_servers(:one)
    server.update_columns(container_state: "exited")
    manager = Servers::WhitelistManager.new(
      server: server,
      connection: FakeConnection.new(calls: [], responses: {}),
    )

    error = assert_raises(MinecraftRcon::UnavailableError) do
      manager.list_entries
    end

    assert_match(/running server/i, error.message)
  end

  test "invalid player names are rejected before command execution" do
    manager = Servers::WhitelistManager.new(
      server: minecraft_servers(:one),
      connection: FakeConnection.new(calls: [], responses: {}),
    )

    assert_raises(MinecraftRcon::CommandError) do
      manager.add_player!("bad player")
    end
  end
end
