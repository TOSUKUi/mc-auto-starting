require "test_helper"

class Servers::PlayerPresenceTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:body, keyword_init: true)
  FakeConnection = Struct.new(:responses, :error, :calls, keyword_init: true) do
    def execute(command, segmented: false)
      calls << [ command, segmented ]
      raise error if error

      responses.fetch(command)
    end
  end

  test "reads online count and player names from list output" do
    server = minecraft_servers(:one)
    connection = FakeConnection.new(
      responses: {
        "list" => FakeResponse.new(body: "There are 2 of a max of 20 players online: Steve, Alex"),
      },
      calls: [],
    )

    payload = Servers::PlayerPresence.new(server: server, connection: connection).read

    assert_equal true, payload.fetch(:available)
    assert_equal 2, payload.fetch(:online_count)
    assert_equal 20, payload.fetch(:max_players)
    assert_equal %w[Steve Alex], payload.fetch(:online_players)
    assert_equal [ [ "list", true ] ], connection.calls
  end

  test "reads zero players when list response has no names" do
    server = minecraft_servers(:one)
    connection = FakeConnection.new(
      responses: {
        "list" => FakeResponse.new(body: "There are 0 of a max of 20 players online:"),
      },
      calls: [],
    )

    payload = Servers::PlayerPresence.new(server: server, connection: connection).read

    assert_equal true, payload.fetch(:available)
    assert_equal 0, payload.fetch(:online_count)
    assert_equal 20, payload.fetch(:max_players)
    assert_equal [], payload.fetch(:online_players)
  end

  test "returns unavailable when the server is not running" do
    server = minecraft_servers(:one)
    server.update_columns(container_state: "exited")

    payload = Servers::PlayerPresence.new(server: server, connection: nil).read

    assert_equal false, payload.fetch(:available)
    assert_equal "player_count_unavailable", payload.fetch(:error_code)
  end

  test "returns unavailable when rcon fails" do
    server = minecraft_servers(:one)
    connection = FakeConnection.new(
      responses: {},
      error: MinecraftRcon::UnavailableError.new("timed out"),
      calls: [],
    )

    payload = Servers::PlayerPresence.new(server: server, connection: connection).read

    assert_equal false, payload.fetch(:available)
    assert_equal "player_count_unavailable", payload.fetch(:error_code)
  end
end
