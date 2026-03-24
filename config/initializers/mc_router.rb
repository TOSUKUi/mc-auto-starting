Rails.application.config.x.mc_router.routes_config_path = ENV.fetch("MC_ROUTER_ROUTES_CONFIG_PATH", Rails.root.join("tmp/mc-router/routes.json").to_s)
Rails.application.config.x.mc_router.reload_strategy = ENV.fetch("MC_ROUTER_RELOAD_STRATEGY", "watch")
Rails.application.config.x.mc_router.reload_command = ENV["MC_ROUTER_RELOAD_COMMAND"]
Rails.application.config.x.mc_router.api_url = ENV["MC_ROUTER_API_URL"]
