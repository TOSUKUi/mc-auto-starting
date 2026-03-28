require "test_helper"

class DiscordInvitationsControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated users to login" do
    get discord_invitations_url

    assert_redirected_to login_path
  end

  test "index shows only invitations issued by the signed in user" do
    sign_in_as(users(:one))

    get discord_invitations_url(format: :json)

    assert_response :success
    assert_equal [ discord_invitations(:one).id, discord_invitations(:two).id ].sort, response.parsed_body.fetch("invitations").map { |invitation| invitation.fetch("id") }.sort
  end

  test "admin can create an operator invitation" do
    sign_in_as(users(:one))

    assert_difference("DiscordInvitation.count", 1) do
      post discord_invitations_url(format: :json), params: {
        discord_invitation: {
          discord_user_id: "777777777777777777",
          invited_user_type: "operator",
          expires_in_days: "7 days",
          note: "ops member",
        },
      }
    end

    assert_response :created
    payload = response.parsed_body

    assert_match(%r{\Ahttp://www\.example\.com/invites/}, payload.fetch("invite_url"))
    assert_equal "777777777777777777", payload.fetch("invitation").fetch("discord_user_id")
    assert_equal "operator", payload.fetch("invitation").fetch("invited_user_type")
    assert_equal "active", payload.fetch("invitation").fetch("status")
  end

  test "operator can create a reader invitation" do
    sign_in_as(users(:two))

    assert_difference("DiscordInvitation.count", 1) do
      post discord_invitations_url(format: :json), params: {
        discord_invitation: {
          discord_user_id: "777777777777777777",
          invited_user_type: "reader",
          expires_in_days: "7 days",
          note: "reader invite",
        },
      }
    end

    assert_response :created
    assert_equal "reader", response.parsed_body.fetch("invitation").fetch("invited_user_type")
  end

  test "operator cannot create an operator invitation" do
    sign_in_as(users(:two))

    assert_no_difference("DiscordInvitation.count") do
      post discord_invitations_url(format: :json), params: {
        discord_invitation: {
          discord_user_id: "777777777777777777",
          invited_user_type: "operator",
          expires_in_days: "7 days",
          note: "forbidden",
        },
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.fetch("errors").fetch("invited_user_type"), "Invited user type is not included in the list"
  end

  test "reader cannot access invitation index" do
    sign_in_as(users(:three))

    get discord_invitations_url(format: :json)

    assert_response :forbidden
  end

  test "invalid expiration selection returns validation errors" do
    sign_in_as(users(:one))

    post discord_invitations_url(format: :json), params: {
      discord_invitation: {
        discord_user_id: "777777777777777777",
        invited_user_type: "reader",
        expires_in_days: "30 days",
        note: "",
      },
    }

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.fetch("errors").fetch("expires_at"), "Expires at must be selected"
  end

  test "invalid discord user id format returns validation errors" do
    sign_in_as(users(:one))

    post discord_invitations_url(format: :json), params: {
      discord_invitation: {
        discord_user_id: "not-a-discord-id",
        invited_user_type: "reader",
        expires_in_days: "7 days",
        note: "",
      },
    }

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.fetch("errors").fetch("discord_user_id"), "Discord user must be a Discord user ID"
  end

  test "issuer can revoke an active invitation" do
    sign_in_as(users(:one))

    patch revoke_discord_invitation_url(discord_invitations(:one), format: :json)

    assert_response :success
    assert_equal "revoked", response.parsed_body.fetch("invitation").fetch("status")
    assert discord_invitations(:one).reload.revoked_at.present?
  end

  test "user cannot revoke another users invitation" do
    sign_in_as(users(:one))

    patch revoke_discord_invitation_url(discord_invitations(:three), format: :json)

    assert_response :not_found
  end
end
