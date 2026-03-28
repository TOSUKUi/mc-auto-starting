module Servers
  class StructuredRconCommand
    class InvalidCommandError < StandardError; end

    PLAYER_NAME_PATTERN = /\A[A-Za-z0-9_]{3,16}\z/
    COMMANDS = {
      "difficulty" => {
        required: %w[difficulty],
        optional: [],
        build: ->(args) { "difficulty #{enum!(args.fetch("difficulty"), %w[peaceful easy normal hard])}" },
      },
      "weather" => {
        required: %w[weather],
        optional: [],
        build: ->(args) { "weather #{enum!(args.fetch("weather"), %w[clear rain thunder])}" },
      },
      "time_set" => {
        required: %w[time],
        optional: [],
        build: ->(args) { "time set #{enum!(args.fetch("time"), %w[day noon night midnight])}" },
      },
      "say" => {
        required: %w[message],
        optional: [],
        build: ->(args) { "say #{string!(args.fetch("message"), field: "message", max_length: 200)}" },
      },
      "kick" => {
        required: %w[player_name],
        optional: %w[reason],
        build: lambda { |args|
          player_name = player_name!(args.fetch("player_name"))
          reason = optional_string(args["reason"], max_length: 200)
          [ "kick", player_name, reason.presence ].compact.join(" ")
        },
      },
      "save_all" => {
        required: [],
        optional: [],
        build: ->(_args) { "save-all" },
      },
      "gamemode" => {
        required: %w[gamemode],
        optional: %w[player_name],
        build: lambda { |args|
          gamemode = enum!(args.fetch("gamemode"), %w[survival creative adventure spectator])
          player_name = optional_player_name(args["player_name"])
          [ "gamemode", gamemode, player_name.presence ].compact.join(" ")
        },
      },
    }.freeze

    def initialize(command_key:, args: {})
      @command_key = command_key.to_s
      @args = (args || {}).to_h.stringify_keys
    end

    def build
      command = COMMANDS[command_key]
      raise InvalidCommandError, "この操作は許可されていません。" unless command

      unknown_keys = args.keys - command.fetch(:required) - command.fetch(:optional)
      raise InvalidCommandError, "この操作は許可されていません。" if unknown_keys.any?

      missing_keys = command.fetch(:required).reject { |key| args[key].present? }
      raise InvalidCommandError, "#{missing_keys.first} is required" if missing_keys.any?

      command.fetch(:build).call(args)
    end

    private
      attr_reader :command_key, :args

      class << self
        def enum!(value, allowed)
          normalized = value.to_s
          raise InvalidCommandError, "value is invalid" unless allowed.include?(normalized)

          normalized
        end

        def string!(value, field:, max_length:)
          normalized = value.to_s.strip
          raise InvalidCommandError, "#{field} is required" if normalized.blank?
          raise InvalidCommandError, "#{field} is too long" if normalized.length > max_length

          normalized
        end

        def optional_string(value, max_length:)
          normalized = value.to_s.strip
          return "" if normalized.blank?
          raise InvalidCommandError, "value is too long" if normalized.length > max_length

          normalized
        end

        def player_name!(value)
          normalized = value.to_s.strip
          raise InvalidCommandError, "player_name is invalid" unless PLAYER_NAME_PATTERN.match?(normalized)

          normalized
        end

        def optional_player_name(value)
          normalized = value.to_s.strip
          return "" if normalized.blank?
          raise InvalidCommandError, "player_name is invalid" unless PLAYER_NAME_PATTERN.match?(normalized)

          normalized
        end
      end

      def enum!(value, allowed) = self.class.enum!(value, allowed)
      def string!(value, field:, max_length:) = self.class.string!(value, field:, max_length:)
      def optional_string(value, max_length:) = self.class.optional_string(value, max_length:)
      def player_name!(value) = self.class.player_name!(value)
      def optional_player_name(value) = self.class.optional_player_name(value)
  end
end
