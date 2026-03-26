module Servers
  class ProvisionServer
    DATA_VOLUME_TARGET = "/data".freeze

    def initialize(server:, docker_client: DockerEngine.build_client, router_applier: Router::ConfigApplier.new)
      @server = server
      @docker_client = docker_client
      @router_publication_sync = Router::PublicationSync.new(
        router_route: server&.router_route,
        enabled: true,
        applier: router_applier,
      )
    end

    def call
      return if server.nil?

      create_volume!
      create_container!
      start_container!
      persist_runtime!
      server.transition_to!(:ready) unless server.status_ready?
      apply_route!
      server
    rescue DockerEngine::Error => error
      rollback_docker_failure!(error)
      raise
    rescue Router::ApplyError => error
      mark_route_failure!(error)
      raise
    end

    private
      attr_reader :server, :docker_client, :router_publication_sync

      def create_volume!
        docker_client.create_volume(
          name: server.volume_name,
          labels: managed_labels,
        )
      end

      def create_container!
        image = MinecraftRuntime.image_for(version_tag: server.minecraft_version)

        response = docker_client.create_container(
          name: server.container_name,
          image: image,
          env: container_env,
          mounts: [ data_volume_mount ],
          labels: managed_labels,
          network_name: MinecraftRuntime.network_name,
          memory_mb: server.memory_mb,
        )

        @container_id = response.fetch("Id")
      rescue DockerEngine::NotFoundError => error
        raise unless missing_image_error?(error)

        docker_client.pull_image(image: image)

        response = docker_client.create_container(
          name: server.container_name,
          image: image,
          env: container_env,
          mounts: [ data_volume_mount ],
          labels: managed_labels,
          network_name: MinecraftRuntime.network_name,
          memory_mb: server.memory_mb,
        )

        @container_id = response.fetch("Id")
      end

      def start_container!
        docker_client.start_container(id: container_id)
      end

      def persist_runtime!
        inspection = docker_client.inspect_container(id_or_name: container_id)

        server.update!(
          container_id: inspection.fetch("Id", container_id),
          container_state: inspection.dig("State", "Status") || "running",
          last_started_at: Time.current,
          last_error_message: nil,
        )
      end

      def apply_route!
        router_publication_sync.call
      end

      def rollback_docker_failure!(error)
        cleanup_runtime_resources!

        if server.persisted?
          server.router_route.update!(enabled: false)
          server.update!(
            container_id: nil,
            container_state: nil,
            last_started_at: nil,
            last_error_message: error.message,
          )
          server.transition_to!(:failed) if server.can_transition_to?(:failed)
        end

        Rails.logger.error("CreateServerJob docker provisioning failed for server=#{server.id}: #{error.class}: #{error.message}")
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

      def cleanup_runtime_resources!
        if container_id.present?
          docker_client.remove_container(id: container_id, force: true)
        elsif server.container_name.present?
          docker_client.remove_container(id: server.container_name, force: true)
        end

        docker_client.remove_volume(name: server.volume_name) if server.volume_name.present?
      rescue DockerEngine::Error => cleanup_error
        Rails.logger.error("CreateServerJob docker cleanup failed for server=#{server.id}: #{cleanup_error.class}: #{cleanup_error.message}")
      end

      def managed_labels
        DockerEngine::ManagedLabels.for_server(minecraft_server: server)
      end

      def data_volume_mount
        {
          Type: "volume",
          Source: server.volume_name,
          Target: DATA_VOLUME_TARGET,
        }
      end

      def container_env
        MinecraftRuntime.container_env(server: server)
      end

      def container_id
        @container_id
      end

      def missing_image_error?(error)
        error.message.to_s.start_with?("No such image:")
      end
  end
end
