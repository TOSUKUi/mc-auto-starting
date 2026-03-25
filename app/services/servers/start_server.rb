module Servers
  class StartServer < LifecycleOperation
    private
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
  end
end
