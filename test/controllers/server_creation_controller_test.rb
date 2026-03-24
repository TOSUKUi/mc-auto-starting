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
    assert_equal "1.21.4", response.parsed_body.fetch("form_defaults").fetch("minecraft_version")
    assert_equal 4096, response.parsed_body.fetch("form_defaults").fetch("memory_mb")
    assert_equal "mc.tosukui.xyz", response.parsed_body.fetch("public_endpoint").fetch("public_domain")
    assert_equal 42434, response.parsed_body.fetch("public_endpoint").fetch("public_port")
    assert_nil response.parsed_body.fetch("public_endpoint").fetch("fqdn")
  end

  test "create echoes submitted values and returns not implemented while backend flow is blocked" do
    sign_in_as(users(:one))

    post servers_url(format: :json), params: {
      minecraft_server: {
        name: "Sky Lab",
        hostname: "  SKY-lab ",
        minecraft_version: "1.21.5",
        memory_mb: 6144,
        disk_mb: 40960,
        template_kind: "fabric",
      },
    }

    assert_response :not_implemented
    assert_match "T-500", response.parsed_body.fetch("blocker_message")
    assert_equal "  SKY-lab ", response.parsed_body.fetch("form_defaults").fetch("hostname")
    assert_equal "sky-lab.mc.tosukui.xyz", response.parsed_body.fetch("public_endpoint").fetch("fqdn")
    assert_equal "sky-lab.mc.tosukui.xyz:42434", response.parsed_body.fetch("public_endpoint").fetch("connection_target")
  end
end
