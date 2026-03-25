module Servers
  class RestartServer < LifecycleOperation
    private
      def perform_docker_operation!
        docker_client.restart_container(id: container_reference, timeout_seconds: restart_timeout_seconds)
      end

      def transition_status
        :restarting
      end

      def mapped_container_state
        "running"
      end

      def next_last_started_at
        Time.current
      end
  end
end
