require "test_helper"

class ServersControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated users to login for index" do
    get servers_url

    assert_redirected_to login_path
  end

  test "index returns only owned and member servers" do
    sign_in_as(users(:two))

    get servers_url(format: :json)

    assert_response :success
    assert_equal [ minecraft_servers(:two).id, minecraft_servers(:one).id ], response.parsed_body.fetch("servers").map { |server| server.fetch("id") }
  end

  test "show allows visible server for member" do
    sign_in_as(users(:three))

    get server_url(minecraft_servers(:one), format: :json)

    assert_response :success
    assert_equal minecraft_servers(:one).id, response.parsed_body.fetch("server").fetch("id")
    assert_equal "operator", response.parsed_body.fetch("server").fetch("access_role")
  end

  test "show returns not found for invisible server" do
    sign_in_as(users(:three))

    get server_url(minecraft_servers(:two), format: :json)

    assert_response :not_found
  end
end
