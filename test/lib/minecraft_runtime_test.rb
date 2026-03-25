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
    assert_equal "router_bridge", MinecraftRuntime.network_name
  end

  test "falls back to defaults when config is blank" do
    Rails.application.config.x.minecraft_runtime.image = nil
    Rails.application.config.x.minecraft_runtime.network_name = ""

    assert_equal "itzg/minecraft-server", MinecraftRuntime.image
    assert_equal "mc_router_net", MinecraftRuntime.network_name
  end
end
