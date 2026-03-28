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
          redirect_to server_path(server), notice: "サーバーの作成を受け付けました。バックグラウンドで準備を進めています。"
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
    sync_server_for_transition_poll!(server)
    route_issue = audit_route!(server)
    server.reload

    respond_to do |format|
      format.html do
        render inertia: "servers/show", props: {
          server: server_detail(server, route_issue_message: route_issue),
        }
      end

      format.json do
        render json: { server: server_detail(server, route_issue_message: route_issue) }
      end
    end
  end

  def destroy
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :destroy?

    Servers::DestroyServer.new(server: server).call

    respond_to do |format|
      format.html do
        redirect_to servers_path, notice: "サーバーを削除しました。"
      end

      format.json do
        head :no_content
      end
    end
  rescue DockerEngine::Error, Router::ApplyError => error
    respond_to do |format|
      format.html do
        redirect_to server_path(server), alert: "サーバーの削除に失敗しました: #{error.message}"
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
    respond_with_server_action(server, notice: "サーバーを起動しました。")
  rescue DockerEngine::Error => error
    respond_with_server_error(server, error)
  end

  def stop
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :stop?

    Servers::StopServer.new(server: server).call
    respond_with_server_action(server, notice: "サーバーを停止しました。")
  rescue DockerEngine::Error => error
    respond_with_server_error(server, error)
  end

  def restart
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :restart?

    Servers::RestartServer.new(server: server).call
    respond_with_server_action(server, notice: "サーバーを再起動しました。")
  rescue DockerEngine::Error => error
    respond_with_server_error(server, error)
  end

  def sync
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :sync?

    Servers::SyncServerState.new(server: server).call
    respond_with_server_action(server, notice: "サーバーの状態を同期しました。")
  rescue DockerEngine::Error => error
    respond_with_server_error(server, error)
  end

  def repair_publication
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :repair_publication?

    Router::RepairPublication.new(server: server).call
    respond_with_server_action(server, notice: "公開設定を再適用しました。")
  rescue Router::ApplyError => error
    respond_with_server_error(server, error)
  end

  def whitelist
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :manage_whitelist?

    respond_to do |format|
      format.json do
        render json: { whitelist: whitelist_payload(server) }
      end

      format.html do
        redirect_to server_path(server)
      end
    end
  rescue MinecraftRcon::Error => error
    respond_with_whitelist_error(server, error)
  end

  def enable_whitelist
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :manage_whitelist?

    whitelist_manager_for(server).enable!
    respond_with_whitelist_action(server, notice: "ホワイトリストを有効化しました。")
  rescue MinecraftRcon::Error => error
    respond_with_whitelist_error(server, error)
  end

  def disable_whitelist
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :manage_whitelist?

    whitelist_manager_for(server).disable!
    respond_with_whitelist_action(server, notice: "ホワイトリストを無効化しました。")
  rescue MinecraftRcon::Error => error
    respond_with_whitelist_error(server, error)
  end

  def reload_whitelist
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :manage_whitelist?

    whitelist_manager_for(server).reload!
    respond_with_whitelist_action(server, notice: "ホワイトリストを再読込しました。")
  rescue MinecraftRcon::Error => error
    respond_with_whitelist_error(server, error)
  end

  def add_whitelist_player
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :manage_whitelist?

    whitelist_manager_for(server).add_player!(whitelist_player_name)
    respond_with_whitelist_action(server, notice: "プレイヤーを追加しました。")
  rescue MinecraftRcon::Error => error
    respond_with_whitelist_error(server, error)
  end

  def remove_whitelist_player
    server = policy_scope(MinecraftServer).find(params[:id])
    authorize server, :manage_whitelist?

    whitelist_manager_for(server).remove_player!(whitelist_player_name)
    respond_with_whitelist_action(server, notice: "プレイヤーを削除しました。")
  rescue MinecraftRcon::Error => error
    respond_with_whitelist_error(server, error)
  end

  private
    def new_server_page_props(form_values: {})
      hostname = normalized_hostname(form_values[:hostname])
      selected_runtime_family = form_values[:runtime_family] || form_values["runtime_family"] || MinecraftRuntime.default_runtime_family
      minecraft_version_options_by_runtime_family = MinecraftRuntime.version_options_by_runtime_family

      {
        form_defaults: default_new_server_form.merge(form_values.symbolize_keys),
        create_quota: create_quota_payload,
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
        owner_display_name: server.owner.operator_display_name,
        access_role: access_role_for(server),
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

    def server_detail(server, route_issue_message: nil)
      summary = server_summary(server)
      visible_actions = detail_visible_actions_for(server)

      summary.merge(
        fqdn: server.fqdn,
        minecraft_version: server.minecraft_version,
        resolved_minecraft_version: server.resolved_minecraft_version,
        minecraft_version_display: server.display_minecraft_version,
        last_error_message: server.last_error_message,
        last_started_at: server.last_started_at&.iso8601,
        uptime_seconds: uptime_seconds_for(server),
        owner_id: server.owner_id,
        runtime: summary.fetch(:runtime).merge(
          backend: server.backend,
        ),
        route_issue_message: route_issue_message,
        can_repair_publication: policy(server).repair_publication?,
        can_manage_members: policy(server).manage_members?,
        can_destroy: policy(server).destroy?,
        can_start: visible_actions[:start],
        can_stop: visible_actions[:stop],
        can_restart: visible_actions[:restart],
        can_sync: visible_actions[:sync],
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

    def create_quota_payload
      {
        applies: Current.user.operator?,
        limit_mb: Current.user.create_memory_quota_limit_mb,
        used_mb: Current.user.owned_server_memory_mb_total,
        remaining_mb: Current.user.remaining_create_memory_quota_mb,
      }
    end

    def detail_visible_actions_for(server)
      status = server.status.to_sym

      {
        start: policy(server).start? && status == :stopped,
        stop: policy(server).stop? && status == :ready,
        restart: policy(server).restart? && status == :ready,
        sync: policy(server).sync? && %i[ready stopped starting stopping restarting degraded failed].include?(status),
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
          redirect_to server_path(server), alert: "サーバー操作に失敗しました: #{error.message}"
        end

        format.json do
          render json: { error: error.message }, status: :unprocessable_entity
        end
      end
    end

    def uptime_seconds_for(server)
      return unless server.last_started_at.present?
      return unless %w[running restarting].include?(server.container_state)

      (Time.current - server.last_started_at).to_i
    end

    def whitelist_payload(server)
      {
        entries: whitelist_manager_for(server).list_entries,
      }
    end

    def whitelist_manager_for(server)
      Servers::WhitelistManager.new(server: server)
    end

    def whitelist_player_name
      params.fetch(:player_name, "").to_s
    end

    def sync_server_for_transition_poll!(server)
      return unless server.status.in?(%w[starting stopping restarting])
      return unless request.headers["X-Server-Poll"] == "1"
      return unless policy(server).sync?

      Servers::SyncServerState.new(server: server).call
    rescue DockerEngine::Error => error
      Rails.logger.warn("Transition poll sync failed for server=#{server.id}: #{error.class}: #{error.message}")
    end

    def audit_route!(server)
      result = Router::PublicationAudit.new.call(router_route: server.router_route)
      result.ok ? nil : result.message
    end

    def respond_with_whitelist_action(server, notice:)
      respond_to do |format|
        format.html do
          redirect_to server_path(server), notice: notice
        end

        format.json do
          render json: { whitelist: whitelist_payload(server) }
        end
      end
    end

    def respond_with_whitelist_error(server, error)
      respond_to do |format|
        format.html do
          redirect_to server_path(server), alert: "ホワイトリスト操作に失敗しました: #{error.message}"
        end

        format.json do
          render json: { error: error.message }, status: :unprocessable_entity
        end
      end
    end
end
