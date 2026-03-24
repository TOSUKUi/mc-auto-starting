class ServerMembersController < InertiaController
  def index
    server = managed_server
    memberships = memberships_for(server)

    respond_to do |format|
      format.html do
        render inertia: "servers/members/index", props: members_page_props(server, memberships)
      end

      format.json do
        render json: members_page_props(server, memberships)
      end
    end
  end

  def create
    server = managed_server
    user = User.find_by(email_address: normalized_email_address)
    membership = server.server_members.new(user: user, role: member_params[:role])
    authorize membership

    if user.nil?
      membership.errors.add(:user, "must exist")
      return render_membership_failure(server, membership, :unprocessable_entity)
    end

    if membership.save
      render_membership_success(server, "Member added.")
    else
      render_membership_failure(server, membership, :unprocessable_entity)
    end
  end

  def update
    membership = managed_membership

    if membership.update(member_params.slice(:role))
      render_membership_success(membership.minecraft_server, "Member role updated.")
    else
      render_membership_failure(membership.minecraft_server, membership, :unprocessable_entity)
    end
  end

  def destroy
    membership = managed_membership
    server = membership.minecraft_server
    membership.destroy!

    render_membership_success(server, "Member removed.")
  end

  private
    def managed_server
      server = policy_scope(MinecraftServer).find(params[:server_id])
      authorize server, :manage_members?
      server
    end

    def managed_membership
      membership = policy_scope(ServerMember)
        .includes(:minecraft_server, :user)
        .find_by!(minecraft_server_id: params[:server_id], id: params[:id])
      authorize membership
      membership
    end

    def member_params
      params.expect(server_member: [ :email_address, :role ])
    end

    def normalized_email_address
      member_params[:email_address].to_s.strip.downcase
    end

    def memberships_for(server)
      policy_scope(ServerMember)
        .where(minecraft_server: server)
        .joins(:user)
        .includes(:user)
        .order("users.email_address ASC", id: :asc)
    end

    def members_page_props(server, memberships)
      {
        server: {
          id: server.id,
          name: server.name,
          fqdn: server.fqdn,
          connection_target: server.connection_target,
          owner_email_address: server.owner.email_address,
        },
        available_roles: ServerMember.roles.keys,
        memberships: memberships.map do |membership|
          {
            id: membership.id,
            email_address: membership.user.email_address,
            role: membership.role,
            created_at: membership.created_at.iso8601,
          }
        end,
        form_defaults: {
          email_address: "",
          role: ServerMember.roles.keys.first,
        },
      }
    end

    def render_membership_success(server, notice)
      respond_to do |format|
        format.html do
          redirect_to server_members_path(server), notice: notice
        end

        format.json do
          render json: members_page_props(server, memberships_for(server)), status: :ok
        end
      end
    end

    def render_membership_failure(server, membership, status)
      respond_to do |format|
        format.html do
          redirect_to server_members_path(server), inertia: { errors: membership.errors.to_hash(true) }, alert: membership.errors.full_messages.to_sentence
        end

        format.json do
          render json: { errors: membership.errors.to_hash(true) }, status: status
        end
      end
    end
end
