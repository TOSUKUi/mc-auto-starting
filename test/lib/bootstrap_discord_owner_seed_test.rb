require "test_helper"

class BootstrapDiscordOwnerSeedTest < ActiveSupport::TestCase
  setup do
    @seeds_path = Rails.root.join("db/seeds.rb")
  end

  test "seed creates the bootstrap discord owner as admin" do
    discord_user_id = "999000111222333"

    with_modified_env(
      "BOOTSTRAP_DISCORD_USER_ID" => discord_user_id,
      "BOOTSTRAP_DISCORD_USERNAME" => "bootstrap-admin"
    ) do
      assert_difference("User.count", 1) do
        load @seeds_path
      end
    end

    user = User.find_by!(discord_user_id: discord_user_id)
    assert_equal "admin", user.user_type
    assert_equal "bootstrap-admin", user.discord_username
  end

  test "seed promotes an existing bootstrap discord user to admin" do
    discord_user_id = "999000111222444"
    user = User.create!(
      discord_user_id: discord_user_id,
      discord_username: "existing-user",
      user_type: "reader",
      password: "password123",
      password_confirmation: "password123",
    )

    with_modified_env(
      "BOOTSTRAP_DISCORD_USER_ID" => discord_user_id,
      "BOOTSTRAP_DISCORD_USERNAME" => "bootstrap-admin"
    ) do
      assert_no_difference("User.count") do
        load @seeds_path
      end
    end

    user.reload
    assert_equal "admin", user.user_type
    assert_equal "bootstrap-admin", user.discord_username
  end

  private
    def with_modified_env(updates)
      original = updates.transform_values { nil }
      updates.each_key { |key| original[key] = ENV[key] }

      updates.each { |key, value| ENV[key] = value }
      yield
    ensure
      original.each do |key, value|
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end
    end
end
