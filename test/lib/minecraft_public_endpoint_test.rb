require "test_helper"

class MinecraftPublicEndpointTest < ActiveSupport::TestCase
  setup do
    @original_public_domain = Rails.application.config.x.minecraft_public_endpoint.public_domain
    @original_public_port = Rails.application.config.x.minecraft_public_endpoint.public_port
  end

  teardown do
    Rails.application.config.x.minecraft_public_endpoint.public_domain = @original_public_domain
    Rails.application.config.x.minecraft_public_endpoint.public_port = @original_public_port
  end

  test "uses configured public domain and port" do
    Rails.application.config.x.minecraft_public_endpoint.public_domain = "play.example.test"
    Rails.application.config.x.minecraft_public_endpoint.public_port = "25565"

    assert_equal "play.example.test", MinecraftPublicEndpoint.public_domain
    assert_equal 25_565, MinecraftPublicEndpoint.public_port
    assert_equal "alpha.play.example.test", MinecraftPublicEndpoint.fqdn_for("Alpha")
    assert_equal "alpha.play.example.test:25565", MinecraftPublicEndpoint.connection_target_for("Alpha")
  end

  test "falls back to defaults when config is blank" do
    Rails.application.config.x.minecraft_public_endpoint.public_domain = nil
    Rails.application.config.x.minecraft_public_endpoint.public_port = nil

    assert_equal "mc.tosukui.xyz", MinecraftPublicEndpoint.public_domain
    assert_equal 42_434, MinecraftPublicEndpoint.public_port
  end
end
