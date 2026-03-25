module Router
  class PublicationSync
    def initialize(router_route:, enabled:, applier: Router::ConfigApplier.new)
      @router_route = router_route
      @enabled = enabled
      @applier = applier
    end

    def call
      return if router_route.nil?

      router_route.update!(
        enabled: enabled,
        last_apply_status: :pending,
      )

      applier.call(routes: RouterRoute.includes(:minecraft_server).to_a)

      router_route.update!(
        last_apply_status: :success,
        last_applied_at: Time.current,
      )
    rescue Router::ApplyError
      handle_apply_failure!
      raise
    end

    private
      attr_reader :router_route, :applier

      def enabled
        @enabled == true
      end

      def handle_apply_failure!
        attributes = { last_apply_status: :failed }
        attributes[:enabled] = false if enabled
        router_route.update!(attributes)
      end
  end
end
