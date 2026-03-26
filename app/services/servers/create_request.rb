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
        normalized_attributes = attributes.symbolize_keys
        runtime_family = normalized_attributes.delete(:runtime_family)
        selected_version = normalized_attributes[:minecraft_version]

        normalized_attributes.merge(
          resolved_minecraft_version: MinecraftRuntime.resolve_version(
            runtime_family: runtime_family,
            version: selected_version,
          ),
          template_kind: runtime_family,
          status: :provisioning,
        )
      end
  end
end
