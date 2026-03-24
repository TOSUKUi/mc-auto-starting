module Servers
  class StopServer < LifecycleOperation
    private
      def provider_method_name
        :stop_server
      end

      def transition_status
        :stopping
      end
  end
end
