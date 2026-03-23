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
    [ hostname, public_domain ].join(".")
  end

  def connection_target_for(hostname)
    "#{fqdn_for(hostname)}:#{public_port}"
  end
end
