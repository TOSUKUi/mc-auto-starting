class DiscordOauthController < ApplicationController
  allow_unauthenticated_access only: %i[ start callback failure ]

  def start
    if discord_oauth_configured?
      redirect_to "/auth/discord", allow_other_host: false
    else
      redirect_to login_path, alert: "Discord ログインはまだ設定されていません。`DISCORD_CLIENT_ID` と `DISCORD_CLIENT_SECRET` を確認してください。"
    end
  end

  def callback
    user = User.find_by_discord_auth(discord_auth)

    if user.present?
      user.apply_discord_auth!(discord_auth)
      start_new_session_for(user)
      clear_pending_invite_token
      redirect_to after_authentication_url, notice: "Discord でログインしました。"
    else
      invitation = pending_invitation

      if invitation&.active? && invitation.discord_user_id == discord_auth.fetch("uid")
        user = build_user_from_invitation!(invitation)
        invitation.consume!
        clear_pending_invite_token
        start_new_session_for(user)
        redirect_to after_authentication_url, notice: "招待を確認して Discord でログインしました。"
      else
        clear_pending_invite_token
        redirect_to login_path, alert: "この Discord アカウントはまだ招待されていません。招待リンクからやり直してください。"
      end
    end
  end

  def failure
    clear_pending_invite_token
    redirect_to login_path, alert: "Discord ログインに失敗しました。時間をおいてもう一度試してください。"
  end

  private
    def discord_oauth_configured?
      ENV["DISCORD_CLIENT_ID"].present? && ENV["DISCORD_CLIENT_SECRET"].present?
    end

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
