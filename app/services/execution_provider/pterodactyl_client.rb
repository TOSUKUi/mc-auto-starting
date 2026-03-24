require "json"
require "net/http"
require "uri"

module ExecutionProvider
  class PterodactylClient < BaseClient
    APPLICATION_API_PREFIX = "/api/application".freeze
    CLIENT_API_PREFIX = "/api/client".freeze

    STATE_TO_RAILS_STATUS = {
      "running" => "ready",
      "starting" => "starting",
      "stopping" => "stopping",
      "offline" => "stopped",
    }.freeze

    def create_server(request)
      response = perform_json_request(
        api: :application,
        method: :post,
        path: "/servers",
        body: request.to_provider_payload,
      )

      build_provider_server(response.fetch("attributes"))
    end

    def delete_server(provider_server_id)
      perform_request(
        api: :application,
        method: :delete,
        path: "/servers/#{provider_server_id}",
      )

      true
    end

    def start_server(provider_server_id)
      power_server(provider_server_id, "start")
    end

    def stop_server(provider_server_id)
      power_server(provider_server_id, "stop")
    end

    def restart_server(provider_server_id)
      power_server(provider_server_id, "restart")
    end

    def fetch_server(provider_server_id)
      response = perform_json_request(
        api: :application,
        method: :get,
        path: "/servers/#{provider_server_id}",
      )

      build_provider_server(response.fetch("attributes"))
    end

    def fetch_status(provider_server_id)
      response = perform_json_request(
        api: :client,
        method: :get,
        path: "/servers/#{provider_server_id}/resources",
      )

      attributes = response.fetch("attributes")
      state = attributes.fetch("current_state")

      ServerStatus.new(
        provider_server_id: provider_server_id,
        state: state,
        rails_status: STATE_TO_RAILS_STATUS.fetch(state, "degraded"),
        raw: attributes,
      )
    end

    private
      def power_server(provider_server_id, signal)
        perform_request(
          api: :client,
          method: :post,
          path: "/servers/#{provider_server_id}/power",
          body: { signal: signal },
        )

        LifecycleResult.new(
          provider_server_id: provider_server_id,
          action: signal,
          accepted: true,
          raw: { "signal" => signal },
        )
      end

      def build_provider_server(attributes)
        primary_allocation = primary_allocation_from(attributes)

        ProviderServer.new(
          provider_server_id: attributes.fetch("id").to_s,
          identifier: attributes["identifier"],
          name: attributes["name"],
          backend_host: primary_allocation&.[]("ip_alias").presence || primary_allocation&.[]("ip"),
          backend_port: primary_allocation&.[]("port"),
          node_id: attributes["node"],
          allocation_id: primary_allocation&.[]("id"),
          raw: attributes,
        )
      end

      def primary_allocation_from(attributes)
        relationships = attributes["relationships"] || {}
        allocations = relationships.dig("allocations", "data")
        return if allocations.blank?

        allocation_entry = allocations.find { |entry| entry.dig("attributes", "is_default") } || allocations.first
        allocation_entry&.fetch("attributes")
      end

      def perform_json_request(**options)
        response = perform_request(**options)
        body = response.body.to_s

        return {} if body.blank?

        JSON.parse(body)
      rescue JSON::ParserError => error
        raise RequestError, "execution provider returned invalid JSON", cause: error
      end

      def perform_request(api:, method:, path:, body: nil)
        uri = build_uri(api, path)
        request = build_request(method, uri, api, body)

        response = Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: uri.scheme == "https",
          open_timeout: configuration.open_timeout,
          read_timeout: configuration.read_timeout,
          write_timeout: configuration.write_timeout,
        ) do |http|
          http.request(request)
        end

        raise_for_response!(response)
        response
      end

      def build_uri(api, path)
        raise ValidationError, "execution provider panel_url is required" if configuration.panel_url.blank?

        prefix = api == :application ? APPLICATION_API_PREFIX : CLIENT_API_PREFIX
        URI.join(
          configuration.panel_url.end_with?("/") ? configuration.panel_url : "#{configuration.panel_url}/",
          "#{prefix.delete_prefix('/')}#{path}",
        )
      end

      def build_request(method, uri, api, body)
        request_class = case method
        when :get then Net::HTTP::Get
        when :post then Net::HTTP::Post
        when :delete then Net::HTTP::Delete
        else
          raise ArgumentError, "unsupported HTTP method: #{method}"
        end

        request = request_class.new(uri)
        request["Accept"] = "application/json"
        request["Authorization"] = "Bearer #{api_key_for(api)}"

        if body
          request["Content-Type"] = "application/json"
          request.body = JSON.generate(body)
        end

        request
      end

      def api_key_for(api)
        key = api == :application ? configuration.application_api_key : configuration.client_api_key
        key.presence || raise(ValidationError, "execution provider #{api} API key is required")
      end

      def raise_for_response!(response)
        status = response.code.to_i
        return if status.between?(200, 299)

        message = error_message_from(response)

        case status
        when 401, 403
          raise AuthenticationError, message
        when 404
          raise NotFoundError, message
        when 409
          raise ConflictError, message
        when 422
          raise ValidationError, message
        else
          raise RequestError, message
        end
      end

      def error_message_from(response)
        body = response.body.to_s
        return "execution provider request failed with status #{response.code}" if body.blank?

        parsed = JSON.parse(body)
        first_error = parsed["errors"]&.first
        detail = first_error&.[]("detail") || parsed["error"] || parsed["message"]

        detail.presence || "execution provider request failed with status #{response.code}"
      rescue JSON::ParserError
        "execution provider request failed with status #{response.code}"
      end
  end
end
