Rails.application.config.x.minecraft_runtime.image = ENV.fetch("MINECRAFT_RUNTIME_IMAGE", "itzg/minecraft-server")
Rails.application.config.x.minecraft_runtime.network_name = ENV.fetch("MINECRAFT_RUNTIME_NETWORK_NAME", "mc_router_net")
