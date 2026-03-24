module Servers
  class SyncServerState
    def initialize(server:, provider_client: ExecutionProvider.build_client)
      @server = server
      @provider_client = provider_client
    end

    def call
      return if server.nil?

      provider_status = provider_client.fetch_status(lifecycle_identifier)
      apply_provider_status!(provider_status.rails_status)
      server
    rescue ExecutionProvider::NotFoundError
      transition_to_degraded!
      server
    end

    private
      attr_reader :server, :provider_client

      def lifecycle_identifier
        server.provider_server_identifier.presence || raise(
          ExecutionProvider::ValidationError,
          "provider_server_identifier is required for lifecycle operations"
        )
      end

      def apply_provider_status!(next_status)
        next_status = next_status.to_sym
        return if server.status.to_sym == next_status

        if server.can_transition_to?(next_status)
          server.transition_to!(next_status)
        else
          transition_to_degraded!
        end
      end

      def transition_to_degraded!
        server.transition_to!(:degraded) if server.can_transition_to?(:degraded)
      end
  end
end
