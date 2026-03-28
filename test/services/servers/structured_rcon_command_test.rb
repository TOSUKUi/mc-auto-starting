require "test_helper"

module Servers
  class StructuredRconCommandTest < ActiveSupport::TestCase
    test "builds difficulty command" do
      command = StructuredRconCommand.new(command_key: "difficulty", args: { difficulty: "hard" }).build

      assert_equal "difficulty hard", command
    end

    test "builds gamemode command with player" do
      command = StructuredRconCommand.new(
        command_key: "gamemode",
        args: { gamemode: "creative", player_name: "TOSUKUi2" },
      ).build

      assert_equal "gamemode creative TOSUKUi2", command
    end

    test "rejects gamemode command without player" do
      error = assert_raises(StructuredRconCommand::InvalidCommandError) do
        StructuredRconCommand.new(
          command_key: "gamemode",
          args: { gamemode: "creative" },
        ).build
      end

      assert_equal "player_name is required", error.message
    end

    test "rejects invalid player name" do
      error = assert_raises(StructuredRconCommand::InvalidCommandError) do
        StructuredRconCommand.new(
          command_key: "gamemode",
          args: { gamemode: "creative", player_name: "bad-name" },
        ).build
      end

      assert_equal "player_name is invalid", error.message
    end

    test "rejects unknown command" do
      error = assert_raises(StructuredRconCommand::InvalidCommandError) do
        StructuredRconCommand.new(command_key: "stop_everything", args: {}).build
      end

      assert_equal "この操作は許可されていません。", error.message
    end
  end
end
