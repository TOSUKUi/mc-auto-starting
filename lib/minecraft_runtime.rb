module MinecraftRuntime
  DEFAULT_IMAGE = "itzg/minecraft-server".freeze
  DEFAULT_NETWORK_NAME = "mc_router_net".freeze

  module_function

  def image
    config.image.to_s.presence || DEFAULT_IMAGE
  end

  def network_name
    config.network_name.to_s.presence || DEFAULT_NETWORK_NAME
  end

  def config
    Rails.application.config.x.minecraft_runtime
  end
end
