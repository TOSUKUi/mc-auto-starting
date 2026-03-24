class ServersController < InertiaController
  def index
    servers = policy_scope(MinecraftServer)
      .includes(:owner, :router_route, :server_members)
      .order(:name)

    respond_to do |format|
      format.html do
        render inertia: "servers/index", props: {
          summary: server_index_summary(servers),
          servers: servers.map { |server| server_summary(server) },
        }
      end

      format.json do
        render json: {
          summary: server_index_summary(servers),
          servers: servers.map { |server| server_summary(server) },
        }
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
      route = server.router_route

      {
        id: server.id,
        name: server.name,
        hostname: server.hostname,
        fqdn: server.fqdn,
        status: server.status,
        connection_target: server.connection_target,
        minecraft_version: server.minecraft_version,
        owner_email_address: server.owner.email_address,
        access_role: access_role_for(server),
        updated_at: server.updated_at.iso8601,
        route: {
          enabled: route&.enabled || false,
          last_apply_status: route&.last_apply_status || "pending",
          last_healthcheck_status: route&.last_healthcheck_status || "unknown",
          last_applied_at: route&.last_applied_at&.iso8601,
          last_healthchecked_at: route&.last_healthchecked_at&.iso8601,
        },
        execution: {
          provider_name: server.provider_name,
          provider_server_id: server.provider_server_id,
          backend_host: server.backend_host,
          backend_port: server.backend_port,
        },
      }
    end

    def server_detail(server)
      server_summary(server).merge(
        fqdn: server.fqdn,
        provider_name: server.provider_name,
        minecraft_version: server.minecraft_version,
        template_kind: server.template_kind,
        owner_id: server.owner_id,
        can_manage_members: policy(server).manage_members?,
      )
    end

    def access_role_for(server)
      return "owner" if server.owner_id == Current.user.id

      server.server_members.find { |member| member.user_id == Current.user.id }&.role
    end

    def server_index_summary(servers)
      {
        total: servers.size,
        owned: servers.count { |server| server.owner_id == Current.user.id },
        member: servers.count { |server| server.owner_id != Current.user.id },
        ready: servers.count(&:status_ready?),
        attention_needed: servers.count { |server| !server.status_ready? || server.router_route&.last_apply_status == "failed" },
      }
    end
end
