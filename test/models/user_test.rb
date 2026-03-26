require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "finds an existing user by discord auth uid" do
    auth = { "uid" => users(:one).discord_user_id }

    assert_equal users(:one), User.find_by_discord_auth(auth)
  end
end
