class BootstrapOwnerLoginHint
  class << self
    def log!(logger: Rails.logger)
      return unless enabled?

      logger.info("Bootstrap Discord owner login: #{login_url}")
      logger.info("After signing in, issue invite links from /discord-invitations.")
    end

    def enabled?
      server_process? && login_url.present? && bootstrap_owner_configured? && discord_oauth_configured?
    end

    def login_url
      return if base_url.blank?

      "#{base_url}/login"
    end

    def base_url
      configured_base_url.presence || default_base_url
    end

    def configured_base_url
      ENV["APP_BASE_URL"].to_s.strip.sub(%r{/\z}, "")
    end

    def default_base_url
      return "http://localhost:3000" if Rails.env.development?
    end

    def bootstrap_owner_configured?
      ENV["BOOTSTRAP_DISCORD_USER_ID"].present?
    end

    def discord_oauth_configured?
      ENV["DISCORD_CLIENT_ID"].present? && ENV["DISCORD_CLIENT_SECRET"].present?
    end

    def server_process?
      defined?(Rails::Server)
    end
  end
end
