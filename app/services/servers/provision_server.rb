module Servers
  class ProvisionServer
    def initialize(server:, provider_client: ExecutionProvider.build_client, router_applier: Router::ConfigApplier.new)
      @server = server
      @provider_client = provider_client
      @router_publication_sync = Router::PublicationSync.new(
        router_route: server&.router_route,
        enabled: true,
        applier: router_applier,
      )
    end

    def call
      return if server.nil?

      profile = ExecutionProvider::ProvisioningProfileResolver.new(server: server).call
      provider_server = provider_client.create_server(build_create_request(profile))

      persist_provider_server!(provider_server)
      server.transition_to!(:ready) unless server.status_ready?
      apply_route!
      server
    rescue ExecutionProvider::Error => error
      rollback_provider_failure!(error)
      raise
    rescue Router::ApplyError => error
      mark_route_failure!(error)
      raise
    end

    private
      attr_reader :server, :provider_client, :router_publication_sync

      def build_create_request(profile)
        ExecutionProvider::CreateServerRequest.new(
          name: server.name,
          external_id: "minecraft-server-#{server.id}",
          owner_id: profile.owner_id,
          node_id: profile.node_id,
          egg_id: profile.egg_id,
          allocation_id: profile.allocation_id,
          memory_mb: server.memory_mb,
          swap_mb: profile.swap_mb,
          disk_mb: server.disk_mb,
          io_weight: profile.io_weight,
          cpu_limit: profile.cpu_limit,
          cpu_pinning: profile.cpu_pinning,
          oom_killer_enabled: profile.oom_killer_enabled,
          allocation_limit: profile.allocation_limit,
          backup_limit: profile.backup_limit,
          database_limit: profile.database_limit,
          environment: profile.environment,
          skip_scripts: profile.skip_scripts,
        )
      end

      def persist_provider_server!(provider_server)
        server.update!(
          provider_server_id: provider_server.provider_server_id,
          provider_server_identifier: provider_server.identifier,
          backend_host: provider_server.backend_host,
          backend_port: provider_server.backend_port,
          last_error_message: nil,
        )
      end

      def apply_route!
        router_publication_sync.call
      end

      def rollback_provider_failure!(error)
        if server.persisted?
          server.router_route.update!(enabled: false)
          server.update!(last_error_message: error.message)
          server.transition_to!(:failed) if server.can_transition_to?(:failed)
        end

        Rails.logger.error("CreateServerJob provider provisioning failed for server=#{server.id}: #{error.class}: #{error.message}")
      end

      def mark_route_failure!(error)
        server.router_route.update!(
          enabled: false,
          last_apply_status: :failed,
        )
        server.update!(last_error_message: error.message)
        server.transition_to!(:unpublished) if server.can_transition_to?(:unpublished)
        Rails.logger.error("CreateServerJob route apply failed for server=#{server.id}: #{error.class}: #{error.message}")
      end
  end
end
