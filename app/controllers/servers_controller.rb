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
  rescue ExecutionProvider::Error, Router::ApplyError => error
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
  rescue ExecutionProvider::Error => error
    respond_with_server_error(server, error)
  end

  def stop
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :stop?

    Servers::StopServer.new(server: server).call
    respond_with_server_action(server, notice: "Server stop accepted.")
  rescue ExecutionProvider::Error => error
    respond_with_server_error(server, error)
  end

  def restart
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :restart?

    Servers::RestartServer.new(server: server).call
    respond_with_server_action(server, notice: "Server restart accepted.")
  rescue ExecutionProvider::Error => error
    respond_with_server_error(server, error)
  end

  def sync
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :sync?

    Servers::SyncServerState.new(server: server).call
    respond_with_server_action(server, notice: "Server status synchronized.")
  rescue ExecutionProvider::Error => error
    respond_with_server_error(server, error)
  end

  private
    def new_server_page_props(form_values: {})
      hostname = normalized_hostname(form_values[:hostname])

      {
        form_defaults: default_new_server_form.merge(form_values.symbolize_keys),
        template_options: template_options,
        provider_name: ExecutionProvider.config.provider_name,
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
        minecraft_version: "1.21.4",
        memory_mb: 4096,
        disk_mb: 20480,
        template_kind: "paper",
      }
    end

    def template_options
      [
        { value: "paper", label: "Paper" },
        { value: "fabric", label: "Fabric" },
        { value: "velocity", label: "Velocity" },
      ]
    end

    def create_server_params
      params.expect(minecraft_server: [ :name, :hostname, :minecraft_version, :memory_mb, :disk_mb, :template_kind ])
    end

    def normalized_hostname(value)
      value.to_s.strip.downcase.presence
    end

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
