require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "defines the canonical global user types" do
    assert_equal %w[admin operator reader], User.user_types.keys
  end

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

  test "defaults new users to reader" do
    user = User.new(password: "password", password_confirmation: "password")

    assert_equal "reader", user.user_type
  end

  test "returns manageable user types by global role" do
    assert_equal %w[admin operator reader], users(:one).manageable_user_types
    assert_equal [ "reader" ], users(:two).manageable_user_types
    assert_equal [], users(:three).manageable_user_types
  end
end
