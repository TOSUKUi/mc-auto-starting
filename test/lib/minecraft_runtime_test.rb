require "test_helper"

class MinecraftRuntimeTest < ActiveSupport::TestCase
  setup do
    @original_image = Rails.application.config.x.minecraft_runtime.image
    @original_network_name = Rails.application.config.x.minecraft_runtime.network_name
  end

  teardown do
    Rails.application.config.x.minecraft_runtime.image = @original_image
    Rails.application.config.x.minecraft_runtime.network_name = @original_network_name
  end

  test "uses configured image and network name" do
    Rails.application.config.x.minecraft_runtime.image = "itzg/minecraft-server:java21"
    Rails.application.config.x.minecraft_runtime.network_name = "router_bridge"

    assert_equal "itzg/minecraft-server:java21", MinecraftRuntime.image
    assert_equal "itzg/minecraft-server:java21", MinecraftRuntime.image(runtime_family: "vanilla")
    assert_equal "router_bridge", MinecraftRuntime.network_name
  end

  test "falls back to defaults when config is blank" do
    Rails.application.config.x.minecraft_runtime.image = nil
    Rails.application.config.x.minecraft_runtime.network_name = ""

    assert_equal "itzg/minecraft-server", MinecraftRuntime.image
    assert_equal "itzg/minecraft-server", MinecraftRuntime.image(runtime_family: "vanilla")
    assert_equal "mc_router_net", MinecraftRuntime.network_name
  end

  test "builds paper runtime env from the server memory and version" do
    server = minecraft_servers(:two)

    assert_equal(
      {
        "EULA" => "TRUE",
        "TYPE" => "PAPER",
        "VERSION" => "1.21.4",
        "MEMORY" => "3584M",
        "HARDCORE" => "FALSE",
        "DIFFICULTY" => "easy",
        "MODE" => "survival",
        "MAX_PLAYERS" => "20",
        "PVP" => "TRUE",
        "ENABLE_RCON" => "TRUE",
        "ENABLE_WHITELIST" => "TRUE",
        "WHITELIST" => "",
        "EXISTING_WHITELIST_FILE" => "SYNCHRONIZE",
        "RCON_PORT" => "25575",
        "RCON_PASSWORD" => MinecraftRcon.password_for(server),
      },
      MinecraftRuntime.container_env(server: server),
    )
  end

  test "builds vanilla runtime env from the server memory and version" do
    server = minecraft_servers(:two)
    server.template_kind = "vanilla"
    server.minecraft_version = "latest"
    server.memory_mb = 4096
    server.hardcore = true
    server.difficulty = "hard"
    server.gamemode = "creative"
    server.max_players = 12
    server.motd = "Vanilla World"
    server.pvp = false

    assert_equal(
      {
        "EULA" => "TRUE",
        "TYPE" => "VANILLA",
        "VERSION" => "latest",
        "MEMORY" => "3584M",
        "HARDCORE" => "TRUE",
        "DIFFICULTY" => "hard",
        "MODE" => "creative",
        "MAX_PLAYERS" => "12",
        "MOTD" => "Vanilla World",
        "PVP" => "FALSE",
        "ENABLE_RCON" => "TRUE",
        "ENABLE_WHITELIST" => "TRUE",
        "WHITELIST" => "",
        "EXISTING_WHITELIST_FILE" => "SYNCHRONIZE",
        "RCON_PORT" => "25575",
        "RCON_PASSWORD" => MinecraftRcon.password_for(server),
      },
      MinecraftRuntime.container_env(server: server),
    )
  end

  test "keeps JVM heap below the container memory limit" do
    assert_equal 3584, MinecraftRuntime.jvm_memory_mb(4096)
    assert_equal 1536, MinecraftRuntime.jvm_memory_mb(2048)
    assert_equal 512, MinecraftRuntime.jvm_memory_mb(512)
  end

  test "builds a tagged image reference from the selected version" do
    Rails.application.config.x.minecraft_runtime.image = "itzg/minecraft-server"

    assert_equal "itzg/minecraft-server", MinecraftRuntime.image_for(version_tag: "1.21.11")
    assert_equal "itzg/minecraft-server", MinecraftRuntime.image_for(version_tag: nil)
    assert_equal "itzg/minecraft-server", MinecraftRuntime.image_for(runtime_family: "vanilla", version_tag: nil)
  end

  test "returns the fallback version options" do
    assert_equal(
      [
        { value: "latest", label: "26.1 (latest)" },
        { value: "26.1", label: "26.1" },
        { value: "1.21.11", label: "1.21.11" },
        { value: "1.20.6", label: "1.20.6" },
      ],
      MinecraftRuntime.fallback_version_options,
    )
  end

  test "returns the runtime family options" do
    assert_equal(
      [
        { value: "vanilla", label: "Java Edition" },
        { value: "paper", label: "Paper" },
      ],
      MinecraftRuntime.runtime_family_options,
    )
  end

  test "returns fallback version options by runtime family from the catalog" do
    assert_equal(
      [
        { value: "latest", label: "26.1 (latest)" },
        { value: "26.1", label: "26.1" },
        { value: "1.21.11", label: "1.21.11" },
      ],
      MinecraftRuntime.fallback_version_options(runtime_family: "vanilla").first(3),
    )

    assert_equal(
      {
        "paper" => [
          { value: "latest", label: "1.21.11 (latest)" },
          { value: "1.21.11", label: "1.21.11" },
          { value: "1.21.10", label: "1.21.10" },
          { value: "1.21.9", label: "1.21.9" },
        ],
        "vanilla" => [
          { value: "latest", label: "26.1 (latest)" },
          { value: "26.1", label: "26.1" },
          { value: "1.21.11", label: "1.21.11" },
          { value: "1.20.6", label: "1.20.6" },
        ],
      },
      MinecraftRuntime.fallback_version_options_by_runtime_family,
    )
  end

  test "returns version source urls by runtime family" do
    assert_match(/qing762\.is-a\.dev\/api\/papermc/, MinecraftRuntime.version_source_url(runtime_family: "paper"))
    assert_match(/piston-meta\.mojang\.com\/mc\/game\/version_manifest_v2\.json/, MinecraftRuntime.version_source_url(runtime_family: "vanilla"))
  end
end
