module Router
  class RouteDefinitionBuilder
    def initialize(router_route:)
      @router_route = router_route
    end

    def call
      raise ArgumentError, "router_route minecraft_server is required" if minecraft_server.nil?
      raise ArgumentError, "router_route is not publishable" unless router_route.publishable?
      raise ArgumentError, "minecraft_server fqdn is required" if router_route.server_address.blank?
      raise ArgumentError, "minecraft_server backend is required" if router_route.backend.blank?

      RouteDefinition.new(
        server_address: router_route.server_address,
        backend: router_route.backend,
      )
    end

    private
      attr_reader :router_route

      def minecraft_server
        router_route.minecraft_server
      end
  end
end
