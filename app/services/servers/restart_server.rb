module Servers
  class RestartServer < StartServer
    private
      def recreate_container_with_current_env!
        docker_client.stop_container(id: container_reference, timeout_seconds: restart_timeout_seconds)
        super
      end

      def transition_status
        :restarting
      end
  end
end
