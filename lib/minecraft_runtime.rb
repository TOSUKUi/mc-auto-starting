module MinecraftRuntime
  DEFAULT_RUNTIME_FAMILY = "paper".freeze
  DEFAULT_IMAGE = "marctv/minecraft-papermc-server".freeze
  DEFAULT_VANILLA_IMAGE = "itzg/minecraft-server".freeze
  DEFAULT_NETWORK_NAME = "mc_router_net".freeze
  DEFAULT_VERSION_TAG = "latest".freeze
  JVM_HEADROOM_MB = 512
  MIN_JVM_MEMORY_MB = 512
  CATALOG_PATH = Rails.root.join("config/minecraft_runtime_catalog.yml")

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
    catalog.map do |runtime_family, attributes|
      {
        value: runtime_family,
        label: attributes.fetch("label"),
      }
    end
  end

  def version_options(runtime_family: DEFAULT_RUNTIME_FAMILY)
    family_catalog(runtime_family).fetch("version_options").map { |option| option.symbolize_keys }
  end

  def version_options_by_runtime_family
    catalog.to_h do |runtime_family, attributes|
      [ runtime_family, attributes.fetch("version_options").map { |option| option.symbolize_keys } ]
    end
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
    runtime_family = value.to_s.presence || DEFAULT_RUNTIME_FAMILY
    catalog.key?(runtime_family) ? runtime_family : DEFAULT_RUNTIME_FAMILY
  end

  def jvm_memory_mb(container_memory_mb)
    memory_mb = Integer(container_memory_mb)
    [ memory_mb - JVM_HEADROOM_MB, MIN_JVM_MEMORY_MB ].max
  end

  def catalog
    @catalog ||= begin
      raw_catalog = YAML.safe_load_file(CATALOG_PATH, aliases: false) || {}
      raw_catalog.deep_stringify_keys
    end
  end

  def family_catalog(runtime_family)
    catalog.fetch(normalize_runtime_family(runtime_family))
  end
end
