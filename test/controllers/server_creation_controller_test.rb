require "test_helper"

class ServerCreationControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated users to login for new" do
    get new_server_url

    assert_redirected_to login_path
  end

  test "new returns create form defaults and endpoint preview metadata" do
    sign_in_as(users(:one))

    get new_server_url(format: :json)

    assert_response :success
    assert_equal "latest", response.parsed_body.fetch("form_defaults").fetch("minecraft_version")
    assert_equal 4096, response.parsed_body.fetch("form_defaults").fetch("memory_mb")
    assert_equal 20480, response.parsed_body.fetch("form_defaults").fetch("disk_mb")
    assert_equal "latest", response.parsed_body.fetch("minecraft_version_options").first.fetch("value")
    assert_not response.parsed_body.fetch("form_defaults").key?("template_kind")
    assert_not response.parsed_body.key?("template_kind")
    assert_not response.parsed_body.key?("runtime_image")
    assert_equal "mc.tosukui.xyz", response.parsed_body.fetch("public_endpoint").fetch("public_domain")
    assert_equal 42434, response.parsed_body.fetch("public_endpoint").fetch("public_port")
    assert_nil response.parsed_body.fetch("public_endpoint").fetch("fqdn")
  end

  test "create accepts the request and forces the paper template baseline" do
    sign_in_as(users(:one))

    assert_difference("MinecraftServer.count", 1) do
      post servers_url(format: :json), params: {
        minecraft_server: {
          name: "Sky Lab",
          hostname: "  SKY-lab ",
          minecraft_version: "1.21.11",
          memory_mb: 6144,
          disk_mb: 40960,
          template_kind: "fabric",
        },
      }
    end

    assert_response :created
    server = response.parsed_body.fetch("server")

    assert_equal "Sky Lab", server.fetch("name")
    assert_equal "sky-lab", server.fetch("hostname")
    assert_equal "sky-lab.mc.tosukui.xyz", server.fetch("fqdn")
    assert_equal "sky-lab.mc.tosukui.xyz:42434", server.fetch("connection_target")
    assert_equal "provisioning", server.fetch("status")
    assert_not server.key?("template_kind")
    assert_equal "mc-server-sky-lab", server.fetch("runtime").fetch("container_name")
    assert_equal "mc-data-sky-lab", server.fetch("runtime").fetch("volume_name")
  end
end
