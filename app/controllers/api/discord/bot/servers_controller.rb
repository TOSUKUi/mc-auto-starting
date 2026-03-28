module Api
  module Discord
    module Bot
      class ServersController < BaseController
        before_action :set_server

        def status
          authorize @server, :show?

          render_success(
            server: @server,
            action: "status",
            message: "サーバー情報を取得しました。",
            result: server_status_payload(@server),
          )
        end

        def start
          authorize @server, :start?
          Servers::StartServer.new(server: @server).call

          render_success(server: @server.reload, action: "start", message: "サーバーを起動しました。", result: server_status_payload(@server))
        rescue DockerEngine::Error => error
          render_failure(error: error.message, error_code: "server_operation_failed", status: :unprocessable_entity)
        end

        def stop
          authorize @server, :stop?
          Servers::StopServer.new(server: @server).call

          render_success(server: @server.reload, action: "stop", message: "サーバーを停止しました。", result: server_status_payload(@server))
        rescue DockerEngine::Error => error
          render_failure(error: error.message, error_code: "server_operation_failed", status: :unprocessable_entity)
        end

        def restart
          authorize @server, :restart?
          Servers::RestartServer.new(server: @server).call

          render_success(server: @server.reload, action: "restart", message: "サーバーを再起動しました。", result: server_status_payload(@server))
        rescue DockerEngine::Error => error
          render_failure(error: error.message, error_code: "server_operation_failed", status: :unprocessable_entity)
        end

        def sync
          authorize @server, :sync?
          Servers::SyncServerState.new(server: @server).call

          render_success(server: @server.reload, action: "sync", message: "サーバーの状態を同期しました。", result: server_status_payload(@server))
        rescue DockerEngine::Error => error
          render_failure(error: error.message, error_code: "server_operation_failed", status: :unprocessable_entity)
        end

        def whitelist_list
          authorize @server, :show?

          render_success(
            server: @server,
            action: "whitelist_list",
            message: "ホワイトリストを取得しました。",
            result: whitelist_payload(@server),
          )
        end

        def whitelist_add
          authorize @server, :manage_whitelist?
          mutate_whitelist!(message: "プレイヤーを追加しました。") do |manager, player_name|
            @server.update!(whitelist_entries: (@server.whitelist_entries + [ player_name ]).uniq.sort)
            manager.add_player!(player_name) if whitelist_live_mutation?(@server)
          end
        end

        def whitelist_remove
          authorize @server, :manage_whitelist?
          mutate_whitelist!(message: "プレイヤーを削除しました。") do |manager, player_name|
            @server.update!(whitelist_entries: @server.whitelist_entries.reject { |entry| entry == player_name })
            manager.remove_player!(player_name) if whitelist_live_mutation?(@server)
          end
        end

        def whitelist_enable
          authorize @server, :manage_whitelist?
          @server.update!(whitelist_enabled: true)
          whitelist_manager_for(@server).enable! if whitelist_live_mutation?(@server)

          render_success(server: @server.reload, action: "whitelist_enable", message: "ホワイトリストを有効化しました。", result: whitelist_payload(@server))
        rescue MinecraftRcon::Error => error
          render_whitelist_failure(error)
        end

        def whitelist_disable
          authorize @server, :manage_whitelist?
          @server.update!(whitelist_enabled: false)
          whitelist_manager_for(@server).disable! if whitelist_live_mutation?(@server)

          render_success(server: @server.reload, action: "whitelist_disable", message: "ホワイトリストを無効化しました。", result: whitelist_payload(@server))
        rescue MinecraftRcon::Error => error
          render_whitelist_failure(error)
        end

        def whitelist_reload
          authorize @server, :manage_whitelist?
          whitelist_manager_for(@server).reload! if whitelist_live_mutation?(@server)

          render_success(server: @server.reload, action: "whitelist_reload", message: "ホワイトリストを再読込しました。", result: whitelist_payload(@server))
        rescue MinecraftRcon::Error => error
          render_failure(error: error.message, error_code: "whitelist_reload_failed", status: :unprocessable_entity)
        end

        def rcon_command
          authorize @server, :rcon_command?

          response_body = Servers::BoundedRconCommand.new(server: @server).execute(command: params.fetch(:command, "").to_s)
          render_success(
            server: @server,
            action: "rcon_command",
            message: "コマンドを実行しました。",
            result: {
              command: params.fetch(:command, "").to_s,
              response_body: response_body,
            },
          )
        rescue Servers::BoundedRconCommand::ForbiddenCommandError => error
          render_failure(error: error.message, error_code: "rcon_command_forbidden", status: :unprocessable_entity)
        rescue MinecraftRcon::Error => error
          render_failure(error: error.message, error_code: "rcon_command_failed", status: :unprocessable_entity)
        end

        private
          def set_server
            @server = policy_scope(MinecraftServer).find(params[:id])
          end

          def server_status_payload(server)
            {
              status: server.status,
              connection_target: server.connection_target,
              minecraft_version: server.display_minecraft_version,
              runtime_family: server.runtime_family,
              owner_display_name: server.owner.operator_display_name,
              last_started_at: server.last_started_at&.iso8601,
              uptime_seconds: uptime_seconds_for(server),
            }
          end

          def whitelist_payload(server)
            {
              enabled: server.whitelist_enabled?,
              entries: server.whitelist_entries,
              staged_only: !whitelist_live_mutation?(server),
            }
          end

          def whitelist_manager_for(server)
            Servers::WhitelistManager.new(server: server)
          end

          def whitelist_live_mutation?(server)
            server.container_state == "running"
          end

          def whitelist_player_name
            params.fetch(:player_name, "").to_s
          end

          def uptime_seconds_for(server)
            return unless server.last_started_at.present?
            return unless %w[running restarting].include?(server.container_state)

            (Time.current - server.last_started_at).to_i
          end

          def mutate_whitelist!(message:)
            player_name = whitelist_player_name
            manager = whitelist_manager_for(@server)
            yield manager, player_name

            render_success(server: @server.reload, action: action_name, message: message, result: whitelist_payload(@server))
          rescue ActiveRecord::RecordInvalid => error
            render_failure(error: error.record.errors.full_messages.to_sentence, error_code: "whitelist_invalid", status: :unprocessable_entity)
          rescue MinecraftRcon::Error => error
            render_whitelist_failure(error)
          end

          def render_whitelist_failure(error)
            render_failure(
              error: "ホワイトリスト設定は保存しましたが、実行中サーバーへの即時反映に失敗しました。次回起動時には保存済み設定が反映されます。原因: #{error.message}",
              error_code: "live_apply_failed",
              status: :unprocessable_entity,
              extra: { desired_state_saved: true },
            )
          end
      end
    end
  end
end
