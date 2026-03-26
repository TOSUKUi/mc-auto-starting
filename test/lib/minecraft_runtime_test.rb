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
    Rails.application.config.x.minecraft_runtime.image = "marctv/minecraft-papermc-server:latest"
    Rails.application.config.x.minecraft_runtime.network_name = "router_bridge"

    assert_equal "marctv/minecraft-papermc-server:latest", MinecraftRuntime.image
    assert_equal "router_bridge", MinecraftRuntime.network_name
  end

  test "falls back to defaults when config is blank" do
    Rails.application.config.x.minecraft_runtime.image = nil
    Rails.application.config.x.minecraft_runtime.network_name = ""

    assert_equal "marctv/minecraft-papermc-server", MinecraftRuntime.image
    assert_equal "mc_router_net", MinecraftRuntime.network_name
  end

  test "builds marctv runtime env from the server memory" do
    server = minecraft_servers(:two)

    assert_equal(
      {
        "MEMORYSIZE" => "6144M",
        "PAPERMC_FLAGS" => "",
      },
      MinecraftRuntime.container_env(server: server),
    )
  end

  test "builds a tagged image reference from the selected version" do
    Rails.application.config.x.minecraft_runtime.image = "marctv/minecraft-papermc-server"

    assert_equal "marctv/minecraft-papermc-server:1.21.11", MinecraftRuntime.image_for(version_tag: "1.21.11")
    assert_equal "marctv/minecraft-papermc-server:latest", MinecraftRuntime.image_for(version_tag: nil)
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
end
