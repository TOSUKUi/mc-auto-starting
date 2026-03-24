require "json"

module Router
  class ConfigRenderer
    def initialize(routes:)
      @routes = routes
    end

    def call
      JSON.pretty_generate(
        {
          "default-server" => nil,
          "mappings" => rendered_mappings,
        },
      ) + "\n"
    end

    private
      attr_reader :routes

      def rendered_mappings
        enabled_routes.filter_map do |route|
          definition = RouteDefinitionBuilder.new(router_route: route).call
          [ definition.server_address, definition.backend ]
        end.sort_by(&:first).to_h
      end

      def enabled_routes
        routes.select(&:enabled?)
      end
  end
end
