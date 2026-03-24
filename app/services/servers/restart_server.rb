module Servers
  class RestartServer < LifecycleOperation
    private
      def provider_method_name
        :restart_server
      end

      def transition_status
        :restarting
      end
  end
end
