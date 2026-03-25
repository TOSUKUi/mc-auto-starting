module DockerEngine
  module ManagedName
    module_function

    def container_name_for(hostname)
      MinecraftServerHostname.container_name_for(hostname)
    end

    def volume_name_for(hostname)
      MinecraftServerHostname.volume_name_for(hostname)
    end
  end
end
