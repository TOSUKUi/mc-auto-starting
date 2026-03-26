require "test_helper"
require "stringio"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "new shows discord-only login entry" do
    get login_path

    assert_response :success
    assert_select "a.auth-submit[href='/auth/discord']", text: "Discord でログイン"
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
end
