class DiscordOauthController < ApplicationController
  allow_unauthenticated_access only: %i[ callback failure ]

  def callback
    user = User.find_by_discord_auth(discord_auth)

    if user.present?
      user.apply_discord_auth!(discord_auth)
      start_new_session_for(user)
      clear_pending_invite_token
      redirect_to after_authentication_url, notice: "Signed in with Discord."
    else
      invitation = pending_invitation

      if invitation&.active? && invitation.discord_user_id == discord_auth.fetch("uid")
        user = build_user_from_invitation!(invitation)
        invitation.consume!
        clear_pending_invite_token
        start_new_session_for(user)
        redirect_to after_authentication_url, notice: "Discord invitation accepted."
      else
        clear_pending_invite_token
        redirect_to login_path, alert: "Discord account is not invited yet."
      end
    end
  end

  def failure
    clear_pending_invite_token
    redirect_to login_path, alert: "Discord sign-in failed."
  end

  private
    def discord_auth
      request.env.fetch("omniauth.auth")
    end

    def pending_invitation
      raw_token = session[:pending_discord_invite_token]
      return if raw_token.blank?

      DiscordInvitation.find_by_raw_token(raw_token)
    end

    def clear_pending_invite_token
      session.delete(:pending_discord_invite_token)
    end

    def build_user_from_invitation!(invitation)
      info = discord_auth.fetch("info", {})
      password = SecureRandom.base58(24)
      email_address = info["email"].presence || "discord-user-#{discord_auth.fetch("uid")}@example.invalid"

      User.create!(
        email_address: email_address,
        discord_user_id: discord_auth.fetch("uid"),
        discord_username: info["name"].presence || "discord-user",
        discord_global_name: info["global_name"],
        discord_avatar: info["image"],
        discord_email: info["email"],
        last_discord_login_at: Time.current,
        password: password,
        password_confirmation: password,
      )
    end
end
