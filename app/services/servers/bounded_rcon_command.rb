module Servers
  class BoundedRconCommand
    class ForbiddenCommandError < StandardError; end

    ALLOWLIST = [
      /\Alist\z/i,
      /\Asay\s+.+\z/i,
      /\Akick\s+[A-Za-z0-9_]{3,16}(?:\s+.+)?\z/i,
      /\Asave-all\z/i,
      /\Atime\s+set\s+.+\z/i,
      /\Aweather\s+.+\z/i,
    ].freeze

    DENYLIST = [
      /\Astop\z/i,
      /\Astart\z/i,
      /\Arestart\z/i,
      /\Areload\z/i,
      /\Aop(?:\s|$)/i,
      /\Adeop(?:\s|$)/i,
      /\Aban(?:\s|$)/i,
      /\Apardon(?:\s|$)/i,
      /\Awhitelist(?:\s|$)/i,
    ].freeze

    def initialize(server:, connection: MinecraftRcon.connection_for(server))
      @server = server
      @connection = connection
    end

    def execute(command:)
      normalized_command = command.to_s.strip
      validate!(normalized_command)
      response = connection.execute(normalized_command, segmented: normalized_command.match?(/\Alist\z/i))
      response.body.to_s.strip
    end

    private
      attr_reader :server, :connection

      def validate!(command)
        raise ForbiddenCommandError, "この RCON コマンドは許可されていません。" if command.blank?
        raise ForbiddenCommandError, "この RCON コマンドは許可されていません。" if DENYLIST.any? { |pattern| pattern.match?(command) }
        raise ForbiddenCommandError, "この RCON コマンドは許可されていません。" unless ALLOWLIST.any? { |pattern| pattern.match?(command) }
        raise MinecraftRcon::UnavailableError, "RCON command requires a running server" unless server.container_state == "running"
      end
  end
end
