module Router
  class McRouterReloader
    def initialize(configuration: Router.config, docker_client: DockerEngine.build_client)
      @configuration = configuration
      @docker_client = docker_client
    end

    def call
      router_container = resolve_router_container

      docker_client.signal_container(
        id: router_container.fetch("Id"),
        signal: configuration.reload_signal,
      )
    rescue DockerEngine::Error => error
      raise ApplyError, "mc_router docker-signal reload failed: #{error.message}"
    end

    private
      attr_reader :configuration, :docker_client

      def resolve_router_container
        matches = docker_client.list_containers(
          filters: { label: configuration.reload_container_labels },
          all: false,
        )

        raise ApplyError, "mc_router reload target was not found" if matches.empty?
        raise ApplyError, "mc_router reload target is ambiguous" if matches.many?

        matches.first
      end
  end
end
