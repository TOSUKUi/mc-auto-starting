module Servers
  class DestroyServer
    def initialize(server:, docker_client: DockerEngine.build_client, router_applier: Router::ConfigApplier.new)
      @server = server
      @docker_client = docker_client
      @router_publication_sync = Router::PublicationSync.new(
        router_route: server&.router_route,
        enabled: false,
        applier: router_applier,
      )
    end

    def call
      return if server.nil?

      server.transition_to!(:deleting) unless server.status_deleting?
      unpublish_route!
      remove_container!
      remove_volume!
      server.destroy!
    rescue Router::ApplyError => error
      mark_route_failure!(error)
      raise
    rescue DockerEngine::Error => error
      log_docker_failure!(error)
      raise
    end

    private
      attr_reader :server, :docker_client, :router_publication_sync

      def unpublish_route!
        router_publication_sync.call
      end

      def remove_container!
        docker_client.remove_container(id: container_reference, force: true) if container_reference.present?
      rescue DockerEngine::NotFoundError
        true
      end

      def remove_volume!
        return if server.volume_name.blank?

        docker_client.remove_volume(name: server.volume_name)
      rescue DockerEngine::NotFoundError
        true
      end

      def container_reference
        server.container_id.presence || server.container_name.presence
      end

      def mark_route_failure!(error)
        server.router_route&.update!(last_apply_status: :failed)
        Rails.logger.error("DestroyServer route apply failed for server=#{server.id}: #{error.class}: #{error.message}")
      end

      def log_docker_failure!(error)
        server.update!(last_error_message: error.message)
        Rails.logger.error("DestroyServer docker cleanup failed for server=#{server.id}: #{error.class}: #{error.message}")
      end
  end
end
