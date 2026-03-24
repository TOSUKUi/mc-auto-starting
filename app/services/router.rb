module Router
  class << self
    def config
      raw_config = Rails.application.config.x.mc_router

      return raw_config if raw_config.is_a?(Configuration)

      Configuration.new(
        routes_config_path: raw_config.routes_config_path,
        reload_strategy: raw_config.reload_strategy,
        reload_command: raw_config.reload_command,
        api_url: raw_config.api_url,
      )
    end
  end
end
