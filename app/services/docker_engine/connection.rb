require "json"

module DockerEngine
  class Connection
    def initialize(configuration:, excon_connection: nil)
      @configuration = configuration
      @excon_connection = excon_connection
    end

    def request(method:, path:, query: nil, body: nil, versioned: true)
      raw_response = excon_connection.request(
        method: method.to_s.upcase,
        path: resolve_path(path, versioned: versioned),
        query: query.presence,
        headers: request_headers(body),
        body: encode_body(body),
      )

      raise_for_status!(raw_response)
      build_response(raw_response)
    rescue Excon::Error::Timeout => error
      raise TimeoutError, "docker engine request timed out: #{error.message}"
    rescue Excon::Error::Socket => error
      raise ConnectionError, "docker engine socket request failed: #{error.message}"
    end

    private
      attr_reader :configuration

      def excon_connection
        @excon_connection ||= Excon.new(
          "http://localhost",
          socket: configuration.socket_path,
          connect_timeout: configuration.open_timeout,
          read_timeout: configuration.read_timeout,
          write_timeout: configuration.write_timeout,
          persistent: false,
        )
      end

      def resolve_path(path, versioned:)
        normalized_path = path.start_with?("/") ? path : "/#{path}"
        return normalized_path unless versioned
        return normalized_path if configuration.api_version.blank?

        "/#{configuration.api_version}#{normalized_path}"
      end

      def request_headers(body)
        headers = { "Accept" => "application/json" }
        headers["Content-Type"] = "application/json" if body.present?
        headers
      end

      def encode_body(body)
        return if body.nil?

        JSON.generate(body)
      end

      def build_response(raw_response)
        headers = normalize_headers(raw_response.headers)
        Response.new(
          status: raw_response.status.to_i,
          headers: headers,
          body: decode_body(raw_response.body, headers),
        )
      end

      def normalize_headers(headers)
        headers.to_h.each_with_object({}) do |(key, value), normalized|
          normalized[key.to_s.downcase] = value
        end
      end

      def decode_body(body, headers)
        return nil if body.blank?
        return JSON.parse(body) if headers["content-type"].to_s.include?("application/json")

        body
      end

      def raise_for_status!(raw_response)
        status = raw_response.status.to_i
        return if status < 400

        response = build_response(raw_response)
        raise error_class_for(status).new(
          error_message_for(status, response.body),
          status: status,
          body: response.body,
        )
      end

      def error_class_for(status)
        case status
        when 400, 422
          ValidationError
        when 404
          NotFoundError
        when 409
          ConflictError
        else
          RequestError
        end
      end

      def error_message_for(status, body)
        return body.dig("message") if body.is_a?(Hash) && body["message"].present?
        return body.dig("error") if body.is_a?(Hash) && body["error"].present?
        return body.dig("errors", 0, "message") if body.is_a?(Hash) && body["errors"].is_a?(Array) && body.dig("errors", 0, "message").present?

        "docker engine request failed with status #{status}"
      end
  end
end
