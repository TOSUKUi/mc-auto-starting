module Servers
  class CreateRequest
    def initialize(actor:, attributes:)
      @actor = actor
      @attributes = attributes
    end

    def call
      server = actor.owned_minecraft_servers.build(server_attributes)
      return server if server.errors.any?
      return server unless server.save

      return server unless server.persisted?

      server.create_router_route!
      CreateServerJob.perform_later(server.id)
      server
    end

    private
      attr_reader :actor, :attributes

      def server_attributes
        attributes.symbolize_keys.merge(
          status: :provisioning,
        )
      end
  end
end
