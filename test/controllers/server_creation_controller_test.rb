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
    assert_equal "vanilla", response.parsed_body.fetch("form_defaults").fetch("runtime_family")
    assert_equal "latest", response.parsed_body.fetch("form_defaults").fetch("minecraft_version")
    assert_equal 4096, response.parsed_body.fetch("form_defaults").fetch("memory_mb")
    assert_equal 20480, response.parsed_body.fetch("form_defaults").fetch("disk_mb")
    assert_equal "vanilla", response.parsed_body.fetch("runtime_family_options").first.fetch("value")
    assert_equal "Java Edition", response.parsed_body.fetch("runtime_family_options").first.fetch("label")
    assert_equal "latest", response.parsed_body.fetch("minecraft_version_options").first.fetch("value")
    assert_equal "latest", response.parsed_body.fetch("minecraft_version_options_by_runtime_family").fetch("paper").first.fetch("value")
    assert_equal "latest", response.parsed_body.fetch("minecraft_version_options_by_runtime_family").fetch("vanilla").first.fetch("value")
    assert_equal "26.1", response.parsed_body.fetch("minecraft_version_options_by_runtime_family").fetch("vanilla").second.fetch("value")
    assert_equal "26.1", response.parsed_body.fetch("minecraft_version_options_by_runtime_family").fetch("vanilla").second.fetch("label")
    assert_equal "1.21.11", response.parsed_body.fetch("minecraft_version_options_by_runtime_family").fetch("paper").second.fetch("label")
    assert_equal "1.21.10", response.parsed_body.fetch("minecraft_version_options_by_runtime_family").fetch("paper").third.fetch("label")
    assert_equal "1.21.10", response.parsed_body.fetch("minecraft_version_options_by_runtime_family").fetch("paper").third.fetch("value")
    assert_not response.parsed_body.fetch("form_defaults").key?("template_kind")
    assert_not response.parsed_body.key?("template_kind")
    assert_not response.parsed_body.key?("runtime_image")
    assert_equal "mc.tosukui.xyz", response.parsed_body.fetch("public_endpoint").fetch("public_domain")
    assert_equal 42434, response.parsed_body.fetch("public_endpoint").fetch("public_port")
    assert_nil response.parsed_body.fetch("public_endpoint").fetch("fqdn")
  end

  test "create accepts the request without exposing legacy template fields" do
    sign_in_as(users(:one))

    assert_difference("MinecraftServer.count", 1) do
      post servers_url(format: :json), params: {
        minecraft_server: {
          name: "Sky Lab",
          hostname: "  SKY-lab ",
          runtime_family: "paper",
          minecraft_version: "1.21.11",
          memory_mb: 4096,
          disk_mb: 40960,
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
    assert_equal "paper", server.fetch("runtime_family")
    assert_equal "1.21.11", server.fetch("resolved_minecraft_version")
    assert_equal "1.21.11", server.fetch("minecraft_version_display")
    assert_not server.key?("template_kind")
    assert_equal "mc-server-sky-lab", server.fetch("runtime").fetch("container_name")
    assert_equal "mc-data-sky-lab", server.fetch("runtime").fetch("volume_name")
    assert_equal "paper", MinecraftServer.find(server.fetch("id")).template_kind
  end

  test "create rejects memory above 4gb and invalid hostname characters" do
    sign_in_as(users(:one))

    assert_no_difference("MinecraftServer.count") do
      post servers_url(format: :json), params: {
        minecraft_server: {
          name: "Too Big",
          hostname: "bad host",
          runtime_family: "paper",
          minecraft_version: "1.21.11",
          memory_mb: 4608,
          disk_mb: 40960,
        },
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.fetch("errors").fetch("hostname"), "Hostname must use lowercase letters, numbers, and internal hyphens only"
    assert_includes response.parsed_body.fetch("errors").fetch("memory_mb"), "Memory mb must be less than or equal to 4096"
  end

  test "create accepts the standard java runtime family" do
    sign_in_as(users(:one))

    assert_difference("MinecraftServer.count", 1) do
      post servers_url(format: :json), params: {
        minecraft_server: {
          name: "Vanilla World",
          hostname: "vanilla-world",
          runtime_family: "vanilla",
          minecraft_version: "latest",
          memory_mb: 2048,
          disk_mb: 20480,
        },
      }
    end

    assert_response :created

    server = MinecraftServer.order(:id).last
    assert_equal "vanilla", server.template_kind
    assert_equal "26.1", server.resolved_minecraft_version
    assert_equal "vanilla", response.parsed_body.fetch("server").fetch("runtime_family")
  end

end
