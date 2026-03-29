Rails.application.config.x.mc_router.routes_config_path =
  if Rails.env.production?
    "/rails/shared/mc-router/routes.json"
  else
    Rails.root.join("tmp/mc-router/routes.json").to_s
  end
Rails.application.config.x.mc_router.reload_strategy = "docker_signal"
Rails.application.config.x.mc_router.reload_command = nil
Rails.application.config.x.mc_router.reload_signal = "HUP"
Rails.application.config.x.mc_router.reload_container_labels = [ "app.kubos.dev/component=mc-router" ]
Rails.application.config.x.mc_router.api_url = nil
