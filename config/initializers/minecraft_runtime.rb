Rails.application.config.x.minecraft_runtime.image = ENV.fetch("MINECRAFT_RUNTIME_IMAGE", "marctv/minecraft-papermc-server")
Rails.application.config.x.minecraft_runtime.vanilla_image = ENV.fetch("MINECRAFT_RUNTIME_VANILLA_IMAGE", "itzg/minecraft-server")
Rails.application.config.x.minecraft_runtime.network_name = ENV.fetch("MINECRAFT_RUNTIME_NETWORK_NAME", "mc_router_net")
