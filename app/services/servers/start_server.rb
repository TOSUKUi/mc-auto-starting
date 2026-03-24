module Servers
  class StartServer < LifecycleOperation
    private
      def provider_method_name
        :start_server
      end

      def transition_status
        :starting
      end
  end
end
