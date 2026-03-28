module Servers
  class ContainerRuntime
    DATA_VOLUME_TARGET = "/data".freeze

    def initialize(server:, docker_client:)
      @server = server
      @docker_client = docker_client
    end

    def create_container!
      image = MinecraftRuntime.image_for(
        runtime_family: server.runtime_family,
        version_tag: server.minecraft_version,
      )

      response = docker_client.create_container(
        name: server.container_name,
        image: image,
        env: MinecraftRuntime.container_env(server: server),
        mounts: [ data_volume_mount ],
        labels: managed_labels,
        network_name: MinecraftRuntime.network_name,
        memory_mb: server.memory_mb,
      )

      response.fetch("Id")
    rescue DockerEngine::NotFoundError => error
      raise unless missing_image_error?(error)

      docker_client.pull_image(image: image)
      retry
    end

    private
      attr_reader :server, :docker_client

      def data_volume_mount
        {
          Type: "volume",
          Source: server.volume_name,
          Target: DATA_VOLUME_TARGET,
        }
      end

      def managed_labels
        DockerEngine::ManagedLabels.for_server(minecraft_server: server)
      end

      def missing_image_error?(error)
        error.message.to_s.start_with?("No such image:")
      end
  end
end
