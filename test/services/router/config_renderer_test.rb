require "json"
require "test_helper"

class Router::ConfigRendererTest < ActiveSupport::TestCase
  test "renders enabled routes into mc-router json config" do
    rendered = Router::ConfigRenderer.new(routes: RouterRoute.includes(:minecraft_server).order(:id)).call
    payload = JSON.parse(rendered)

    assert_nil payload.fetch("default-server")
    assert_equal({ "main-survival.mc.tosukui.xyz" => "10.0.0.21:25565" }, payload.fetch("mappings"))
  end

  test "sorts mappings by hostname for deterministic output" do
    alpha_server = MinecraftServer.create!(
      owner: users(:one),
      name: "Alpha",
      hostname: "alpha",
      status: :ready,
      provider_name: "stub_provider",
      provider_server_id: "srv-alpha",
      provider_server_identifier: "alpha1234",
      backend_host: "10.0.0.30",
      backend_port: 25565,
      minecraft_version: "1.21.4",
      memory_mb: 4096,
      disk_mb: 20480,
      template_kind: "paper",
    )
    alpha_route = RouterRoute.create!(minecraft_server: alpha_server, enabled: true, last_apply_status: :success)

    rendered = Router::ConfigRenderer.new(routes: [ alpha_route, router_routes(:one) ]).call
    payload = JSON.parse(rendered)

    assert_equal [ "alpha.mc.tosukui.xyz", "main-survival.mc.tosukui.xyz" ], payload.fetch("mappings").keys
  end
end
