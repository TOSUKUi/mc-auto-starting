class DiscordOauthController < ApplicationController
  allow_unauthenticated_access only: %i[ callback failure ]

  def callback
    user = User.find_by_discord_auth(discord_auth)

    if user.present?
      user.apply_discord_auth!(discord_auth)
      start_new_session_for(user)
      redirect_to after_authentication_url, notice: "Signed in with Discord."
    else
      redirect_to login_path, alert: "Discord account is not invited yet."
    end
  end

  def failure
    redirect_to login_path, alert: "Discord sign-in failed."
  end

  private
    def discord_auth
      request.env.fetch("omniauth.auth")
    end
end
