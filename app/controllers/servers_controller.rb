class ServersController < InertiaController
  def new
    authorize MinecraftServer, :create?

    respond_to do |format|
      format.html do
        render inertia: "servers/new", props: new_server_page_props
      end

      format.json do
        render json: new_server_page_props
      end
    end
  end

  def create
    authorize MinecraftServer, :create?

    server = Servers::CreateRequest.new(
      actor: Current.user,
      attributes: create_server_params.to_h,
    ).call

    if server.persisted?
      respond_to do |format|
        format.html do
          redirect_to server_path(server), notice: "Server create request accepted. Provisioning is running in the background."
        end

        format.json do
          render json: { server: server_detail(server) }, status: :created
        end
      end
    else
      respond_to do |format|
        format.html do
          render inertia: "servers/new", props: new_server_page_props(
            form_values: create_server_params.to_h,
          ), status: :unprocessable_entity
        end

        format.json do
          render json: { errors: server.errors.to_hash(true) }, status: :unprocessable_entity
        end
      end
    end
  end

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

  def destroy
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :destroy?

    Servers::DestroyServer.new(server: server).call

    respond_to do |format|
      format.html do
        redirect_to servers_path, notice: "Server deletion completed."
      end

      format.json do
        head :no_content
      end
    end
  rescue DockerEngine::Error, Router::ApplyError => error
    respond_to do |format|
      format.html do
        redirect_to server_path(server), alert: "Server deletion failed: #{error.message}"
      end

      format.json do
        render json: { error: error.message }, status: :unprocessable_entity
      end
    end
  end

  def start
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :start?

    Servers::StartServer.new(server: server).call
    respond_with_server_action(server, notice: "Server start accepted.")
  rescue DockerEngine::Error => error
    respond_with_server_error(server, error)
  end

  def stop
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :stop?

    Servers::StopServer.new(server: server).call
    respond_with_server_action(server, notice: "Server stop accepted.")
  rescue DockerEngine::Error => error
    respond_with_server_error(server, error)
  end

  def restart
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :restart?

    Servers::RestartServer.new(server: server).call
    respond_with_server_action(server, notice: "Server restart accepted.")
  rescue DockerEngine::Error => error
    respond_with_server_error(server, error)
  end

  def sync
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :sync?

    Servers::SyncServerState.new(server: server).call
    respond_with_server_action(server, notice: "Server status synchronized.")
  rescue DockerEngine::Error => error
    respond_with_server_error(server, error)
  end

  private
    def new_server_page_props(form_values: {})
      hostname = normalized_hostname(form_values[:hostname])
      selected_runtime_family = form_values[:runtime_family] || form_values["runtime_family"] || MinecraftRuntime.default_runtime_family
      minecraft_version_options_by_runtime_family = MinecraftRuntime.version_options_by_runtime_family

      {
        form_defaults: default_new_server_form.merge(form_values.symbolize_keys),
        runtime_family_options: MinecraftRuntime.runtime_family_options,
        minecraft_version_options: minecraft_version_options_by_runtime_family.fetch(
          MinecraftRuntime.normalize_runtime_family(selected_runtime_family),
          [],
        ),
        minecraft_version_options_by_runtime_family: minecraft_version_options_by_runtime_family,
        public_endpoint: {
          public_domain: MinecraftPublicEndpoint.public_domain,
          public_port: MinecraftPublicEndpoint.public_port,
          fqdn: hostname.present? ? MinecraftPublicEndpoint.fqdn_for(hostname) : nil,
          connection_target: hostname.present? ? MinecraftPublicEndpoint.connection_target_for(hostname) : nil,
        },
      }
    end

    def default_new_server_form
      {
        name: "",
        hostname: "",
        runtime_family: MinecraftRuntime.default_runtime_family,
        minecraft_version: MinecraftRuntime.default_version_tag,
        memory_mb: MinecraftServer::MAX_MEMORY_MB,
        disk_mb: 20480,
      }
    end

    def create_server_params
      params.expect(minecraft_server: [ :name, :hostname, :runtime_family, :minecraft_version, :memory_mb, :disk_mb ]).to_h
    end

    def normalized_hostname(value)
      MinecraftServer.normalize_hostname(value)
    end

    def server_summary(server)
      route = server.router_route

      {
        id: server.id,
        name: server.name,
        hostname: server.hostname,
        fqdn: server.fqdn,
        status: server.status,
        runtime_family: server.runtime_family,
        connection_target: server.connection_target,
        minecraft_version: server.minecraft_version,
        resolved_minecraft_version: server.resolved_minecraft_version,
        minecraft_version_display: server.display_minecraft_version,
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
        runtime: {
          container_name: server.container_name,
          container_id: server.container_id,
          container_state: server.container_state,
          volume_name: server.volume_name,
        },
      }
    end

    def server_detail(server)
      summary = server_summary(server)

      summary.merge(
        fqdn: server.fqdn,
        minecraft_version: server.minecraft_version,
        resolved_minecraft_version: server.resolved_minecraft_version,
        minecraft_version_display: server.display_minecraft_version,
        last_error_message: server.last_error_message,
        last_started_at: server.last_started_at&.iso8601,
        owner_id: server.owner_id,
        runtime: summary.fetch(:runtime).merge(
          backend: server.backend,
        ),
        can_manage_members: policy(server).manage_members?,
        can_destroy: policy(server).destroy?,
        can_start: policy(server).start?,
        can_stop: policy(server).stop?,
        can_restart: policy(server).restart?,
        can_sync: policy(server).sync?,
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

    def respond_with_server_action(server, notice:)
      respond_to do |format|
        format.html do
          redirect_to server_path(server), notice: notice
        end

        format.json do
          render json: { server: server_detail(server.reload) }
        end
      end
    end

    def respond_with_server_error(server, error)
      respond_to do |format|
        format.html do
          redirect_to server_path(server), alert: "Server operation failed: #{error.message}"
        end

        format.json do
          render json: { error: error.message }, status: :unprocessable_entity
        end
      end
    end
end
