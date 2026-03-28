module MinecraftRuntime
  DEFAULT_RUNTIME_FAMILY = "vanilla".freeze
  DEFAULT_IMAGE = "itzg/minecraft-server".freeze
  DEFAULT_VANILLA_IMAGE = "itzg/minecraft-server".freeze
  DEFAULT_NETWORK_NAME = "mc_router_net".freeze
  DEFAULT_VERSION_TAG = "latest".freeze
  JVM_HEADROOM_MB = 512
  MIN_JVM_MEMORY_MB = 512
  CATALOG_PATH = Rails.root.join("config/minecraft_runtime_catalog.yml")
  STABLE_VERSION_PATTERN = /\A\d+(?:\.\d+)+\z/

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
    image(runtime_family: runtime_family)
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
    VersionCatalog.new.version_options(runtime_family: runtime_family)
  end

  def version_options_by_runtime_family
    VersionCatalog.new.version_options_by_runtime_family
  end

  def resolve_version(runtime_family: DEFAULT_RUNTIME_FAMILY, version:)
    VersionCatalog.new.resolve_version(runtime_family: runtime_family, version: version)
  end

  def fallback_version_options(runtime_family: DEFAULT_RUNTIME_FAMILY)
    family_catalog(runtime_family).fetch("version_options").map { |option| option.symbolize_keys }
  end

  def fallback_version_options_by_runtime_family
    catalog.to_h do |runtime_family, attributes|
      [ runtime_family, attributes.fetch("version_options").map { |option| option.symbolize_keys } ]
    end
  end

  def version_source_url(runtime_family: DEFAULT_RUNTIME_FAMILY)
    case normalize_runtime_family(runtime_family)
    when "vanilla"
      config.vanilla_version_manifest_url.to_s
    else
      config.paper_version_manifest_url.to_s
    end
  end

  def version_source_urls
    catalog.keys.to_h do |runtime_family|
      [ runtime_family, version_source_url(runtime_family: runtime_family) ]
    end
  end

  def version_options_cache_ttl
    config.version_options_cache_ttl
  end

  def container_env(server:)
    base_env = startup_settings_env(server).merge(
      "ENABLE_RCON" => "TRUE",
      "ENABLE_WHITELIST" => server.whitelist_enabled? ? "TRUE" : "FALSE",
      "WHITELIST" => server.whitelist_entries_csv,
      "EXISTING_WHITELIST_FILE" => "SYNCHRONIZE",
      "RCON_PORT" => MinecraftRcon.port.to_s,
      "RCON_PASSWORD" => MinecraftRcon.password_for(server),
    )

    case normalize_runtime_family(server.runtime_family)
    when "vanilla"
      base_env.merge(
        "EULA" => "TRUE",
        "TYPE" => "VANILLA",
        "VERSION" => normalize_version_tag(server.minecraft_version),
        "MEMORY" => "#{jvm_memory_mb(server.memory_mb)}M",
      )
    else
      base_env.merge(
        "EULA" => "TRUE",
        "TYPE" => "PAPER",
        "VERSION" => normalize_version_tag(server.minecraft_version),
        "MEMORY" => "#{jvm_memory_mb(server.memory_mb)}M",
      )
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

  def startup_settings_env(server)
    {
      "HARDCORE" => server.hardcore? ? "TRUE" : "FALSE",
      "DIFFICULTY" => server.difficulty,
      "MODE" => server.gamemode,
      "MAX_PLAYERS" => server.max_players.to_s,
      "PVP" => server.pvp? ? "TRUE" : "FALSE",
    }.tap do |env|
      env["MOTD"] = server.motd if server.motd.present?
    end
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
