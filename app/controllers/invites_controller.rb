class InvitesController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    invitation = DiscordInvitation.find_by_raw_token(params[:token])

    if invitation&.active?
      session[:pending_discord_invite_token] = params[:token]
      redirect_to "/auth/discord", allow_other_host: false
    else
      redirect_to login_path, alert: "招待リンクが無効か期限切れです。"
    end
  end
end
