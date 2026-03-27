require "test_helper"

class ServerMembersControllerTest < ActionDispatch::IntegrationTest
  test "owner can view memberships for owned server" do
    sign_in_as(users(:one))

    get server_members_url(minecraft_servers(:one), format: :json)

    assert_response :success
    assert_equal minecraft_servers(:one).id, response.parsed_body.fetch("server").fetch("id")
    assert_equal [ server_members(:two).id, server_members(:one).id ], response.parsed_body.fetch("memberships").map { |membership| membership.fetch("id") }
  end

  test "non owner cannot view memberships page" do
    sign_in_as(users(:two))

    get server_members_url(minecraft_servers(:one), format: :json)

    assert_response :forbidden
  end

  test "admin can view memberships for non-owned server" do
    sign_in_as(users(:one))

    get server_members_url(minecraft_servers(:two), format: :json)

    assert_response :success
    assert_equal minecraft_servers(:two).id, response.parsed_body.fetch("server").fetch("id")
  end

  test "owner can add an existing user as a member by discord user id" do
    sign_in_as(users(:two))

    post server_members_url(minecraft_servers(:two), format: :json), params: {
      server_member: {
        discord_user_id: "100000000000000003",
        role: "viewer",
      },
    }

    assert_response :success

    membership = minecraft_servers(:two).server_members.find_by!(user: users(:three))
    assert_equal "viewer", membership.role
  end

  test "adding a missing user returns validation errors" do
    sign_in_as(users(:two))

    post server_members_url(minecraft_servers(:two), format: :json), params: {
      server_member: {
        discord_user_id: "999999999999999999",
        role: "viewer",
      },
    }

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.fetch("errors").fetch("user"), "User が見つかりません"
  end

  test "owner can update a membership role" do
    sign_in_as(users(:one))

    patch server_member_url(minecraft_servers(:one), server_members(:one), format: :json), params: {
      server_member: {
        role: "manager",
      },
    }

    assert_response :success
    assert_equal "manager", server_members(:one).reload.role
  end

  test "owner can remove a membership" do
    sign_in_as(users(:one))

    assert_difference("ServerMember.count", -1) do
      delete server_member_url(minecraft_servers(:one), server_members(:two), format: :json)
    end

    assert_response :success
  end

  test "admin can add membership on non-owned server" do
    sign_in_as(users(:one))

    post server_members_url(minecraft_servers(:two), format: :json), params: {
      server_member: {
        discord_user_id: "100000000000000003",
        role: "manager",
      },
    }

    assert_response :success
    assert_equal "manager", minecraft_servers(:two).server_members.find_by!(user: users(:three)).role
  end
end
