module Router
  class RouteDefinitionBuilder
    def initialize(router_route:)
      @router_route = router_route
    end

    def call
      raise ArgumentError, "router_route minecraft_server is required" if minecraft_server.nil?
      raise ArgumentError, "minecraft_server hostname is required" if minecraft_server.hostname.blank?
      raise ArgumentError, "minecraft_server backend_host is required" if minecraft_server.backend_host.blank?
      raise ArgumentError, "minecraft_server backend_port is required" if minecraft_server.backend_port.blank?

      RouteDefinition.new(
        server_address: minecraft_server.fqdn,
        backend: "#{minecraft_server.backend_host}:#{minecraft_server.backend_port}",
      )
    end

    private
      attr_reader :router_route

      def minecraft_server
        router_route.minecraft_server
      end
  end
end
