module Servers
  class StopServer < LifecycleOperation
    private
      def perform_docker_operation!
        docker_client.stop_container(id: container_reference, timeout_seconds: stop_timeout_seconds)
      end

      def transition_status
        :stopping
      end

      def mapped_container_state
        "exited"
      end
  end
end
