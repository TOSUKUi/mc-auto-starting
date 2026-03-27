require "json"

module Router
  class PublicationAudit
    Result = Data.define(:ok, :message)

    def initialize(configuration: Router.config)
      @configuration = configuration
    end

    def call(router_route:)
      return success_result if router_route.nil?

      mappings = load_mappings
      route_key = router_route.server_address

      if router_route.enabled?
        expected_backend = router_route.backend
        actual_backend = mappings[route_key]
        return success_result if actual_backend == expected_backend

        router_route.update!(last_apply_status: :failed)
        return failure_result("公開設定の反映を確認できませんでした。#{route_key} が期待した接続先を向いていません。")
      end

      return success_result unless mappings.key?(route_key)

      router_route.update!(last_apply_status: :failed)
      failure_result("非公開のはずのサーバーが公開設定に残っています。")
    rescue Errno::ENOENT
      router_route&.update!(last_apply_status: :failed)
      failure_result("公開設定ファイルが見つかりません。")
    rescue JSON::ParserError
      router_route&.update!(last_apply_status: :failed)
      failure_result("公開設定ファイルを読み取れません。")
    end

    private
      attr_reader :configuration

      def load_mappings
        parsed = JSON.parse(File.read(configuration.routes_config_path))
        parsed.fetch("mappings", {})
      end

      def success_result
        Result.new(ok: true, message: nil)
      end

      def failure_result(message)
        Result.new(ok: false, message: message)
      end
  end
end
