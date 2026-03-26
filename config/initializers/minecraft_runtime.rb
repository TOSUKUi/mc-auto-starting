Rails.application.config.x.minecraft_runtime.image = ENV.fetch("MINECRAFT_RUNTIME_IMAGE", "itzg/minecraft-server")
Rails.application.config.x.minecraft_runtime.vanilla_image = ENV.fetch("MINECRAFT_RUNTIME_VANILLA_IMAGE", "itzg/minecraft-server")
Rails.application.config.x.minecraft_runtime.network_name = ENV.fetch("MINECRAFT_RUNTIME_NETWORK_NAME", "mc_router_net")
Rails.application.config.x.minecraft_runtime.vanilla_version_manifest_url = ENV.fetch("MINECRAFT_RUNTIME_VANILLA_VERSION_MANIFEST_URL", "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json")
Rails.application.config.x.minecraft_runtime.paper_version_manifest_url = ENV.fetch("MINECRAFT_RUNTIME_PAPER_VERSION_MANIFEST_URL", "https://qing762.is-a.dev/api/papermc")
Rails.application.config.x.minecraft_runtime.version_options_cache_ttl = ENV.fetch("MINECRAFT_RUNTIME_VERSION_OPTIONS_CACHE_TTL", 300).to_i.seconds
