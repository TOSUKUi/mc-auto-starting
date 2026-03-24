module Servers
  class LifecycleOperation
    def initialize(server:, provider_client: ExecutionProvider.build_client)
      @server = server
      @provider_client = provider_client
    end

    def call
      return if server.nil?

      provider_client.public_send(provider_method_name, lifecycle_identifier)
      server.transition_to!(transition_status) if server.can_transition_to?(transition_status)
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

      def provider_method_name
        raise NotImplementedError, "#{self.class.name} must implement #provider_method_name"
      end

      def transition_status
        raise NotImplementedError, "#{self.class.name} must implement #transition_status"
      end
  end
end
