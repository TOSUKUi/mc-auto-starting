require "test_helper"

class ServerCreationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_provisioning_templates = Rails.application.config.x.execution_provider.provisioning_templates
  end

  teardown do
    Rails.application.config.x.execution_provider.provisioning_templates = @original_provisioning_templates
  end

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
    assert_equal "fabric", response.parsed_body.fetch("form_defaults").fetch("template_kind")
    assert_equal %w[fabric paper velocity], response.parsed_body.fetch("template_options").map { |item| item.fetch("value") }
    assert_equal "mc.tosukui.xyz", response.parsed_body.fetch("public_endpoint").fetch("public_domain")
    assert_equal 42434, response.parsed_body.fetch("public_endpoint").fetch("public_port")
    assert_nil response.parsed_body.fetch("public_endpoint").fetch("fqdn")
  end

  test "create accepts the request and returns the created server payload" do
    sign_in_as(users(:one))

    assert_difference("MinecraftServer.count", 1) do
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
    end

    assert_response :created
    server = response.parsed_body.fetch("server")

    assert_equal "Sky Lab", server.fetch("name")
    assert_equal "sky-lab", server.fetch("hostname")
    assert_equal "sky-lab.mc.tosukui.xyz", server.fetch("fqdn")
    assert_equal "sky-lab.mc.tosukui.xyz:42434", server.fetch("connection_target")
    assert_equal "provisioning", server.fetch("status")
  end

  test "create rejects an unavailable template before provisioning starts" do
    Rails.application.config.x.execution_provider.provisioning_templates = {
      "paper" => @original_provisioning_templates.fetch("paper"),
    }

    sign_in_as(users(:one))

    assert_no_difference("MinecraftServer.count") do
      post servers_url(format: :json), params: {
        minecraft_server: {
          name: "Sky Lab",
          hostname: "sky-lab",
          minecraft_version: "1.21.5",
          memory_mb: 6144,
          disk_mb: 40960,
          template_kind: "fabric",
        },
      }
    end

    assert_response :unprocessable_entity
    assert_equal [ "Template kind is not configured for the active execution provider" ], response.parsed_body.fetch("errors").fetch("template_kind")
  end
end
