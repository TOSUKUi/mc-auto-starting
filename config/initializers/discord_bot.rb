Rails.application.config.x.discord_bot.api_token = ENV["DISCORD_BOT_API_TOKEN"].to_s
Rails.application.config.x.discord_bot.allowed_cidrs =
  ENV.fetch("DISCORD_BOT_ALLOWED_CIDRS", "172.16.0.0/12")
    .split(",")
    .map(&:strip)
    .reject(&:blank?)
