require "test_helper"

class MinecraftRuntimeTest < ActiveSupport::TestCase
  setup do
    @original_image = Rails.application.config.x.minecraft_runtime.image
    @original_vanilla_image = Rails.application.config.x.minecraft_runtime.vanilla_image
    @original_network_name = Rails.application.config.x.minecraft_runtime.network_name
  end

  teardown do
    Rails.application.config.x.minecraft_runtime.image = @original_image
    Rails.application.config.x.minecraft_runtime.vanilla_image = @original_vanilla_image
    Rails.application.config.x.minecraft_runtime.network_name = @original_network_name
  end

  test "uses configured image and network name" do
    Rails.application.config.x.minecraft_runtime.image = "marctv/minecraft-papermc-server:latest"
    Rails.application.config.x.minecraft_runtime.vanilla_image = "itzg/minecraft-server:java21"
    Rails.application.config.x.minecraft_runtime.network_name = "router_bridge"

    assert_equal "marctv/minecraft-papermc-server:latest", MinecraftRuntime.image
    assert_equal "itzg/minecraft-server:java21", MinecraftRuntime.image(runtime_family: "vanilla")
    assert_equal "router_bridge", MinecraftRuntime.network_name
  end

  test "falls back to defaults when config is blank" do
    Rails.application.config.x.minecraft_runtime.image = nil
    Rails.application.config.x.minecraft_runtime.vanilla_image = ""
    Rails.application.config.x.minecraft_runtime.network_name = ""

    assert_equal "marctv/minecraft-papermc-server", MinecraftRuntime.image
    assert_equal "itzg/minecraft-server", MinecraftRuntime.image(runtime_family: "vanilla")
    assert_equal "mc_router_net", MinecraftRuntime.network_name
  end

  test "builds marctv runtime env from the server memory" do
    server = minecraft_servers(:two)

    assert_equal(
      {
        "MEMORYSIZE" => "3584M",
        "PAPERMC_FLAGS" => "",
      },
      MinecraftRuntime.container_env(server: server),
    )
  end

  test "builds vanilla runtime env from the server memory and version" do
    server = minecraft_servers(:two)
    server.template_kind = "vanilla"
    server.minecraft_version = "latest"
    server.memory_mb = 4096

    assert_equal(
      {
        "EULA" => "TRUE",
        "TYPE" => "VANILLA",
        "VERSION" => "latest",
        "MEMORY" => "3584M",
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
    Rails.application.config.x.minecraft_runtime.image = "marctv/minecraft-papermc-server"
    Rails.application.config.x.minecraft_runtime.vanilla_image = "itzg/minecraft-server"

    assert_equal "marctv/minecraft-papermc-server:1.21.11", MinecraftRuntime.image_for(version_tag: "1.21.11")
    assert_equal "marctv/minecraft-papermc-server:latest", MinecraftRuntime.image_for(version_tag: nil)
    assert_equal "itzg/minecraft-server:latest", MinecraftRuntime.image_for(runtime_family: "vanilla", version_tag: nil)
  end

  test "returns the configured version options" do
    assert_equal(
      [
        { value: "latest", label: "最新 (latest)" },
        { value: "1.21.11", label: "1.21.11" },
        { value: "1.21.11-127", label: "1.21.11-127" },
      ],
      MinecraftRuntime.version_options,
    )
  end

  test "returns the runtime family options" do
    assert_equal(
      [
        { value: "paper", label: "Paper" },
        { value: "vanilla", label: "Java" },
      ],
      MinecraftRuntime.runtime_family_options,
    )
  end
end
