module Servers
  class StartServer < LifecycleOperation
    def call
      return if server.nil?

      container_reference
      recreate_container_with_current_env!
      super
    end

    private
      def recreate_container_with_current_env!
        docker_client.remove_container(id: container_reference, force: false) if server.container_id.present? || server.container_name.present?

        new_container_id = container_runtime.create_container!
        server.update!(container_id: new_container_id)
      end

      def perform_docker_operation!
        docker_client.start_container(id: container_reference)
      end

      def transition_status
        :starting
      end

      def mapped_container_state
        "running"
      end

      def next_last_started_at
        Time.current
      end

      def container_runtime
        @container_runtime ||= Servers::ContainerRuntime.new(server: server, docker_client: docker_client)
      end
  end
end
