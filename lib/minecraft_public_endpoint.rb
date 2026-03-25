module MinecraftPublicEndpoint
  PUBLIC_DOMAIN = "mc.tosukui.xyz".freeze
  PUBLIC_PORT = 42_434

  module_function

  def public_domain
    PUBLIC_DOMAIN
  end

  def public_port
    PUBLIC_PORT
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
end
