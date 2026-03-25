module MinecraftPublicEndpoint
  DEFAULT_PUBLIC_DOMAIN = "mc.tosukui.xyz".freeze
  DEFAULT_PUBLIC_PORT = 42_434

  module_function

  def public_domain
    config.public_domain.to_s.presence || DEFAULT_PUBLIC_DOMAIN
  end

  def public_port
    Integer(config.public_port.presence || DEFAULT_PUBLIC_PORT)
  end

  def fqdn_for(hostname)
    normalized = MinecraftServerHostname.normalize(hostname)
    return if normalized.blank?

    [ normalized, public_domain ].join(".")
  end

  def connection_target_for(hostname)
    fqdn = fqdn_for(hostname)
    return if fqdn.blank?

    "#{fqdn}:#{public_port}"
  end

  def config
    Rails.application.config.x.minecraft_public_endpoint
  end
end
