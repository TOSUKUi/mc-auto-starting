if defined?(OmniAuth)
  OmniAuth.config.allowed_request_methods = %i[get post]
  OmniAuth.config.silence_get_warning = true

  Rails.application.config.middleware.use OmniAuth::Builder do
    if ENV["DISCORD_CLIENT_ID"].present? && ENV["DISCORD_CLIENT_SECRET"].present?
      provider(
        :discord,
        ENV.fetch("DISCORD_CLIENT_ID"),
        ENV.fetch("DISCORD_CLIENT_SECRET"),
        scope: "identify",
      )
    end
  end
end
