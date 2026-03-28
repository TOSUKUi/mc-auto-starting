Rails.application.config.x.minecraft_rcon.port = ENV.fetch("MINECRAFT_RCON_PORT", 25_575).to_i
Rails.application.config.x.minecraft_rcon.password_secret = ENV["MINECRAFT_RCON_PASSWORD_SECRET"]
Rails.application.config.x.minecraft_rcon.connect_timeout = ENV.fetch("MINECRAFT_RCON_CONNECT_TIMEOUT", 5).to_f
Rails.application.config.x.minecraft_rcon.command_timeout = ENV.fetch("MINECRAFT_RCON_COMMAND_TIMEOUT", 5).to_f
Rails.application.config.x.minecraft_rcon.segmented_response_wait = ENV.fetch("MINECRAFT_RCON_SEGMENTED_RESPONSE_WAIT", 0.15).to_f
