Rails.application.config.x.minecraft_public_endpoint.public_domain = ENV.fetch("MINECRAFT_PUBLIC_DOMAIN", "mc.tosukui.xyz")
Rails.application.config.x.minecraft_public_endpoint.public_port = ENV.fetch("MINECRAFT_PUBLIC_PORT", 42_434)
