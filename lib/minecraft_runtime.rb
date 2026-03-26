module MinecraftRuntime
  DEFAULT_RUNTIME_FAMILY = "paper".freeze
  DEFAULT_IMAGE = "marctv/minecraft-papermc-server".freeze
  DEFAULT_VANILLA_IMAGE = "itzg/minecraft-server".freeze
  DEFAULT_NETWORK_NAME = "mc_router_net".freeze
  DEFAULT_VERSION_TAG = "latest".freeze
  JVM_HEADROOM_MB = 512
  MIN_JVM_MEMORY_MB = 512
  RUNTIME_FAMILY_OPTIONS = [
    { value: "paper", label: "Paper" },
    { value: "vanilla", label: "Java" },
  ].freeze
  VERSION_OPTIONS = [
    { value: "latest", label: "最新 (latest)" },
    { value: "1.21.11", label: "1.21.11" },
    { value: "1.21.11-127", label: "1.21.11-127" },
  ].freeze

  module_function

  def image(runtime_family: DEFAULT_RUNTIME_FAMILY)
    case normalize_runtime_family(runtime_family)
    when "vanilla"
      config.vanilla_image.to_s.presence || DEFAULT_VANILLA_IMAGE
    else
      config.image.to_s.presence || DEFAULT_IMAGE
    end
  end

  def image_for(version_tag:, runtime_family: DEFAULT_RUNTIME_FAMILY)
    repository = image(runtime_family: runtime_family)
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

  def default_runtime_family
    DEFAULT_RUNTIME_FAMILY
  end

  def runtime_family_options
    RUNTIME_FAMILY_OPTIONS.map(&:dup)
  end

  def version_options(runtime_family: DEFAULT_RUNTIME_FAMILY)
    VERSION_OPTIONS.map(&:dup)
  end

  def container_env(server:)
    case normalize_runtime_family(server.runtime_family)
    when "vanilla"
      {
        "EULA" => "TRUE",
        "TYPE" => "VANILLA",
        "VERSION" => normalize_version_tag(server.minecraft_version),
        "MEMORY" => "#{jvm_memory_mb(server.memory_mb)}M",
      }
    else
      {
        "MEMORYSIZE" => "#{jvm_memory_mb(server.memory_mb)}M",
        "PAPERMC_FLAGS" => "",
      }
    end
  end

  def config
    Rails.application.config.x.minecraft_runtime
  end

  def normalize_version_tag(value)
    value.to_s.presence || DEFAULT_VERSION_TAG
  end

  def normalize_runtime_family(value)
    value.to_s.presence || DEFAULT_RUNTIME_FAMILY
  end

  def jvm_memory_mb(container_memory_mb)
    memory_mb = Integer(container_memory_mb)
    [ memory_mb - JVM_HEADROOM_MB, MIN_JVM_MEMORY_MB ].max
  end
end
