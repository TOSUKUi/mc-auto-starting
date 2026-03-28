require "test_helper"
require "stringio"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "new shows discord-only login entry" do
    get login_path

    assert_response :success
    assert_select "a.auth-submit[href='#{discord_login_path}']", text: "Discordでログイン"
    assert_select "input[type=email]", count: 0
    assert_select "input[type=password]", count: 0
  end

  test "create route is not available" do
    post login_path

    assert_response :not_found
  end

  test "destroy" do
    sign_in_as(User.take)

    delete logout_path

    assert_redirected_to login_path
    assert_empty cookies[:session_id]
  end

  test "destroy uses inertia location for inertia requests" do
    sign_in_as(User.take)

    delete logout_path, headers: inertia_headers

    assert_response :conflict
    assert_equal login_path, response.headers["X-Inertia-Location"]
    assert_empty cookies[:session_id]
  end

  private
    def inertia_headers
      {
        "X-Inertia" => "true",
        "X-Inertia-Version" => InertiaRails.configuration.version.to_s,
      }
    end
end
