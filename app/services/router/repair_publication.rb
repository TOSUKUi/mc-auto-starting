module Router
  class RepairPublication
    def initialize(server:, applier: Router::ConfigApplier.new, audit: Router::PublicationAudit.new)
      @server = server
      @applier = applier
      @audit = audit
    end

    def call
      return server if server.nil? || server.router_route.nil?

      Router::PublicationSync.new(
        router_route: server.router_route,
        enabled: server.route_should_be_enabled?,
        applier: applier,
      ).call

      result = audit.call(router_route: server.router_route.reload)
      raise Router::ApplyError, result.message unless result.ok

      server.update!(last_error_message: nil)
      server
    rescue Router::ApplyError => error
      server.update!(last_error_message: error.message)
      raise
    end

    private
      attr_reader :server, :applier, :audit
  end
end
