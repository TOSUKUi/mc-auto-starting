module Servers
  class CreateRequest
    def initialize(actor:, attributes:)
      @actor = actor
      @attributes = attributes
    end

    def call
      server = actor.owned_minecraft_servers.build(server_attributes)
      return server if server.errors.any?
      validate_runtime_selection(server)
      return server if server.errors.any?
      enforce_memory_quota(server)
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

      def validate_runtime_selection(server)
        runtime_family = server.template_kind
        version = server.minecraft_version.to_s
        return if runtime_family.blank? || version.blank?
        return unless MinecraftRuntime.catalog.key?(runtime_family)

        allowed_versions = MinecraftRuntime.version_options(runtime_family: runtime_family).map { |option| option[:value] || option["value"] }
        return if allowed_versions.include?(version)

        server.errors.add(:minecraft_version, "は選択肢にない値です。")
      end

      def enforce_memory_quota(server)
        limit = actor.create_memory_quota_limit_mb
        return if limit.blank?

        projected_total = actor.owned_server_memory_mb_total + server.memory_mb.to_i
        return if projected_total <= limit

        remaining = actor.remaining_create_memory_quota_mb
        server.errors.add(:memory_mb, "は上限 #{limit} MB を超えます。残りは #{remaining} MB です。")
      end
  end
end
