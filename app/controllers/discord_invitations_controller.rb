class DiscordInvitationsController < InertiaController
  EXPIRATION_OPTIONS = {
    "1 day" => 1.day,
    "3 days" => 3.days,
    "7 days" => 7.days,
    "14 days" => 14.days,
  }.freeze

  def index
    authorize DiscordInvitation, :index?
    invitations = policy_scope(DiscordInvitation).includes(:invited_by).recent_first

    respond_to do |format|
      format.html do
        render inertia: "discord_invitations/index", props: page_props(invitations)
      end

      format.json do
        render json: page_props(invitations)
      end
    end
  end

  def create
    authorize DiscordInvitation, :create?

    invitation, raw_token = DiscordInvitation.issue!(
      invited_by: Current.user,
      discord_user_id: invitation_params[:discord_user_id],
      expires_at: expires_at_from_params,
      note: invitation_params[:note],
    )

    respond_to do |format|
      format.html do
        redirect_to discord_invitations_path,
          notice: "招待リンクを発行しました。",
          flash: { invite_url: invite_url_for(raw_token) }
      end

      format.json do
        render json: {
          invitation: invitation_payload(invitation),
          invite_url: invite_url_for(raw_token),
        }, status: :created
      end
    end
  rescue ActiveRecord::RecordInvalid => error
    render_create_failure(error.record)
  end

  def revoke
    invitation = managed_invitation
    invitation.revoke!

    respond_to do |format|
      format.html do
        redirect_to discord_invitations_path, notice: "招待リンクを無効化しました。"
      end

      format.json do
        render json: { invitation: invitation_payload(invitation.reload) }, status: :ok
      end
    end
  end

  private
    def managed_invitation
      invitation = policy_scope(DiscordInvitation).find(params[:id])
      authorize invitation, :revoke?
      invitation
    end

    def invitation_params
      params.expect(discord_invitation: [ :discord_user_id, :note, :expires_in_days ])
    end

    def expires_at_from_params
      duration = EXPIRATION_OPTIONS.fetch(invitation_params[:expires_in_days]) { raise KeyError }
      Time.current + duration
    rescue KeyError
      record = DiscordInvitation.new
      record.errors.add(:expires_at, "must be selected")
      raise ActiveRecord::RecordInvalid, record
    end

    def page_props(invitations)
      {
        invitations: invitations.map { |invitation| invitation_payload(invitation) },
        form_defaults: {
          discord_user_id: "",
          note: "",
          expires_in_days: EXPIRATION_OPTIONS.keys.third,
        },
        expiration_options: EXPIRATION_OPTIONS.keys.map { |value| { value: value, label: expiration_option_label(value) } },
        pending_invite_url: flash[:invite_url],
      }
    end

    def invitation_payload(invitation)
      {
        id: invitation.id,
        discord_user_id: invitation.discord_user_id,
        note: invitation.note,
        status: invitation.status,
        expires_at: invitation.expires_at&.iso8601,
        used_at: invitation.used_at&.iso8601,
        revoked_at: invitation.revoked_at&.iso8601,
        created_at: invitation.created_at.iso8601,
      }
    end

    def expiration_option_label(value)
      case value
      when "1 day"
        "1日"
      when "3 days"
        "3日"
      when "7 days"
        "7日"
      when "14 days"
        "14日"
      else
        value
      end
    end

    def invite_url_for(raw_token)
      "#{request.base_url}/invites/#{raw_token}"
    end

    def render_create_failure(invitation)
      respond_to do |format|
        format.html do
          redirect_to discord_invitations_path,
            inertia: { errors: invitation.errors.to_hash(true) },
            alert: invitation.errors.full_messages.to_sentence
        end

        format.json do
          render json: { errors: invitation.errors.to_hash(true) }, status: :unprocessable_entity
        end
      end
    end
end
