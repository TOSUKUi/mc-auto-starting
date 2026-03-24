module Servers
  class DestroyServer
    def initialize(server:, provider_client: ExecutionProvider.build_client, router_applier: Router::ConfigApplier.new)
      @server = server
      @provider_client = provider_client
      @router_applier = router_applier
    end

    def call
      return if server.nil?

      server.transition_to!(:deleting) unless server.status_deleting?
      unpublish_route!
      delete_provider_server!
      server.destroy!
    rescue Router::ApplyError => error
      mark_route_failure!(error)
      raise
    rescue ExecutionProvider::Error => error
      log_provider_failure!(error)
      raise
    end

    private
      attr_reader :server, :provider_client, :router_applier

      def unpublish_route!
        return unless server.router_route

        server.router_route.update!(enabled: false)

        router_applier.call(routes: RouterRoute.includes(:minecraft_server).to_a)

        server.router_route.update!(
          last_apply_status: :success,
          last_applied_at: Time.current,
        )
      end

      def delete_provider_server!
        return if server.provider_server_id.blank?

        provider_client.delete_server(server.provider_server_id)
      end

      def mark_route_failure!(error)
        server.router_route&.update!(last_apply_status: :failed)
        Rails.logger.error("DestroyServer route apply failed for server=#{server.id}: #{error.class}: #{error.message}")
      end

      def log_provider_failure!(error)
        Rails.logger.error("DestroyServer provider delete failed for server=#{server.id}: #{error.class}: #{error.message}")
      end
  end
end
