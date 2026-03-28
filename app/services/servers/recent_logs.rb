module Servers
  class RecentLogs
    DEFAULT_TAIL = 120

    def initialize(server:, docker_client: DockerEngine.build_client)
      @server = server
      @docker_client = docker_client
    end

    def read(tail: DEFAULT_TAIL)
      target = server.container_id.presence || server.container_name.presence
      return unavailable unless target

      raw_logs = docker_client.container_logs(id: target, tail: tail)
      lines = extract_lines(raw_logs)

      {
        available: true,
        lines: lines.last(Integer(tail)),
        truncated: lines.size >= Integer(tail),
      }
    rescue DockerEngine::Error
      unavailable
    end

    private
      attr_reader :server, :docker_client

      def unavailable
        {
          available: false,
          error_code: "logs_unavailable",
        }
      end

      def extract_lines(raw_logs)
        text = docker_frame_stream?(raw_logs) ? decode_frame_stream(raw_logs) : raw_logs.to_s
        text
          .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
          .split(/\r?\n/)
          .reject(&:blank?)
      end

      def docker_frame_stream?(raw_logs)
        bytes = raw_logs.to_s.b
        return false if bytes.bytesize < 8

        stream_type = bytes.getbyte(0)
        payload_size = bytes.byteslice(4, 4)&.unpack1("N")

        [ 1, 2 ].include?(stream_type) && payload_size && payload_size >= 0 && bytes.bytesize >= 8 + payload_size
      end

      def decode_frame_stream(raw_logs)
        bytes = raw_logs.to_s.b
        offset = 0
        decoded = +""

        while offset + 8 <= bytes.bytesize
          header = bytes.byteslice(offset, 8)
          stream_type = header.getbyte(0)
          break unless [ 1, 2 ].include?(stream_type)

          payload_size = header.byteslice(4, 4).unpack1("N")
          offset += 8
          break if offset + payload_size > bytes.bytesize

          decoded << bytes.byteslice(offset, payload_size)
          offset += payload_size
        end

        decoded
      end
  end
end
