class ServersController < InertiaController
  def index
    servers = policy_scope(MinecraftServer).includes(:server_members).order(:name)

    respond_to do |format|
      format.html do
        render inertia: "servers/index", props: {
          servers: servers.map { |server| server_summary(server) },
        }
      end

      format.json do
        render json: { servers: servers.map { |server| server_summary(server) } }
      end
    end
  end

  def show
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :show?

    respond_to do |format|
      format.html do
        render inertia: "servers/show", props: {
          server: server_detail(server),
        }
      end

      format.json do
        render json: { server: server_detail(server) }
      end
    end
  end

  private
    def server_summary(server)
      {
        id: server.id,
        name: server.name,
        hostname: server.hostname,
        status: server.status,
        connection_target: server.connection_target,
        access_role: access_role_for(server),
      }
    end

    def server_detail(server)
      server_summary(server).merge(
        fqdn: server.fqdn,
        provider_name: server.provider_name,
        minecraft_version: server.minecraft_version,
        template_kind: server.template_kind,
        owner_id: server.owner_id,
      )
    end

    def access_role_for(server)
      return "owner" if server.owner_id == Current.user.id

      server.server_members.find { |member| member.user_id == Current.user.id }&.role
    end
end
