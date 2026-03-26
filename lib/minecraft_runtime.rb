module MinecraftRuntime
  DEFAULT_IMAGE = "marctv/minecraft-papermc-server".freeze
  DEFAULT_NETWORK_NAME = "mc_router_net".freeze
  DEFAULT_VERSION_TAG = "latest".freeze
  JVM_HEADROOM_MB = 512
  MIN_JVM_MEMORY_MB = 512
  VERSION_OPTIONS = [
    { value: "latest", label: "最新 (latest)" },
    { value: "1.21.11", label: "1.21.11" },
    { value: "1.21.11-127", label: "1.21.11-127" },
  ].freeze

  module_function

  def image
    config.image.to_s.presence || DEFAULT_IMAGE
  end

  def image_for(version_tag:)
    repository = image
    resolved_tag = normalize_version_tag(version_tag)
    return repository if repository.match?(/:[^\/]+\z/)

    "#{repository}:#{resolved_tag}"
  end

  def network_name
    config.network_name.to_s.presence || DEFAULT_NETWORK_NAME
  end

  def default_version_tag
    DEFAULT_VERSION_TAG
  end

  def version_options
    VERSION_OPTIONS.map(&:dup)
  end

  def container_env(server:)
    {
      "MEMORYSIZE" => "#{jvm_memory_mb(server.memory_mb)}M",
      "PAPERMC_FLAGS" => "",
    }
  end

  def config
    Rails.application.config.x.minecraft_runtime
  end

  def normalize_version_tag(value)
    value.to_s.presence || DEFAULT_VERSION_TAG
  end

  def jvm_memory_mb(container_memory_mb)
    memory_mb = Integer(container_memory_mb)
    [ memory_mb - JVM_HEADROOM_MB, MIN_JVM_MEMORY_MB ].max
  end
end
