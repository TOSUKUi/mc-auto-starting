module Servers
  class PlayerPresence
    UNAVAILABLE_PAYLOAD = {
      available: false,
      error_code: "player_count_unavailable",
    }.freeze

    LIST_PATTERN = /\AThere are (?<online>\d+) of a max of (?<max>\d+) players online:?\s*(?<players>.*)\z/i
    FALLBACK_PATTERN = /\AThere are (?<online>\d+) players online:?\s*(?<players>.*)\z/i

    def initialize(server:, connection: MinecraftRcon.connection_for(server))
      @server = server
      @connection = connection
    end

    def read
      return unavailable unless server.container_state == "running"

      response = connection.execute("list", segmented: true)
      parse_response(response.body.to_s)
    rescue MinecraftRcon::Error
      unavailable
    end

    private
      attr_reader :server, :connection

      def parse_response(body)
        normalized = body.to_s.strip
        return payload_from_match(LIST_PATTERN.match(normalized)) if LIST_PATTERN.match?(normalized)
        return payload_from_match(FALLBACK_PATTERN.match(normalized)) if FALLBACK_PATTERN.match?(normalized)

        unavailable
      end

      def payload_from_match(match)
        {
          available: true,
          online_count: match[:online].to_i,
          max_players: match.names.include?("max") ? match[:max].to_i : nil,
          online_players: parse_players(match[:players]),
        }.compact
      end

      def parse_players(raw_players)
        raw_players.to_s.split(",").map(&:strip).reject(&:blank?)
      end

      def unavailable
        UNAVAILABLE_PAYLOAD.dup
      end
  end
end
