require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated users to login" do
    get root_url

    assert_redirected_to login_path
  end

  test "allows authenticated users to access root" do
    sign_in_as(users(:one))

    get root_url

    assert_response :success
  end
end
