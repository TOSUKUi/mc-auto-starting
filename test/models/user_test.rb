require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "prefers discord global name for operator display" do
    assert_equal "Discord One", users(:one).operator_display_name
  end

  test "falls back to discord username and fixed label for operator display" do
    user = users(:one)
    user.discord_global_name = nil
    assert_equal "discord-one", user.operator_display_name

    user.discord_username = nil
    assert_equal "未設定ユーザー", user.operator_display_name
  end

  test "finds an existing user by discord auth uid" do
    auth = { "uid" => users(:one).discord_user_id }

    assert_equal users(:one), User.find_by_discord_auth(auth)
  end
end
