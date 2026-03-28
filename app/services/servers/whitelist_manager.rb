module Servers
  class WhitelistManager
    PLAYER_NAME_PATTERN = /\A[A-Za-z0-9_]{3,16}\z/

    def initialize(server:, connection: MinecraftRcon.connection_for(server))
      @server = server
      @connection = connection
    end

    def list_entries
      parse_entries(execute!("whitelist list", segmented: true))
    end

    def enable!
      execute!("whitelist on")
    end

    def disable!
      execute!("whitelist off")
    end

    def reload!
      execute!("whitelist reload")
    end

    def add_player!(player_name)
      execute!("whitelist add #{validated_player_name(player_name)}")
    end

    def remove_player!(player_name)
      execute!("whitelist remove #{validated_player_name(player_name)}")
    end

    private
      attr_reader :server, :connection

      def execute!(command, segmented: false)
        ensure_running!
        response = connection.execute(command, segmented: segmented)
        response.body.to_s.strip
      end

      def ensure_running!
        return if server.container_state == "running"

        raise MinecraftRcon::UnavailableError, "whitelist operations require a running server"
      end

      def validated_player_name(player_name)
        normalized = player_name.to_s.strip
        return normalized if normalized.match?(PLAYER_NAME_PATTERN)

        raise MinecraftRcon::CommandError, "invalid player name"
      end

      def parse_entries(response)
        normalized_response = response.to_s.strip
        return [] if normalized_response.blank?
        return [] if normalized_response.match?(/\AThere are no whitelisted players\z/i)

        entries = normalized_response.split(":", 2).last.to_s.split(",").map(&:strip).reject(&:blank?)
        entries.sort
      end
  end
end
