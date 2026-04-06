require "fileutils"
require "securerandom"

module Servers
  class WorldTransferOperation
    STAGING_ROOT = Rails.root.join("tmp/world_transfers")
    HELPER_IMAGE = "alpine:3.21".freeze
    HELPER_MEMORY_MB = 256

    class Error < StandardError; end
    class MissingManagedVolumeError < Error; end
    class ServerNotStoppedError < Error; end
    class InvalidArchiveError < Error; end
    class HelperCommandFailedError < Error; end

    private
      attr_reader :server, :docker_client, :request_id, :staging_root, :helper_image

      def initialize(
        server:,
        docker_client: DockerEngine.build_client,
        request_id: SecureRandom.uuid,
        staging_root: STAGING_ROOT,
        helper_image: HELPER_IMAGE
      )
        @server = server
        @docker_client = docker_client
        @request_id = request_id
        @staging_root = Pathname.new(staging_root)
        @helper_image = helper_image
      end

      def prepare_transfer!
        sync_server_state!
        ensure_server_stopped!
        ensure_managed_volume!
      end

      def staging_directory
        @staging_directory ||= staging_root.join(request_id)
      end

      def create_staging_directory!
        FileUtils.mkdir_p(staging_directory)
      end

      def cleanup_staging_directory!
        return unless staging_directory.exist?

        FileUtils.remove_entry(staging_directory)
        nil
      rescue StandardError => error
        Rails.logger.warn("World transfer cleanup failed for server=#{server.id} request=#{request_id}: #{error.class}: #{error.message}")
        "一時ファイルの後片付けに失敗しました。`tmp/world_transfers/#{request_id}` を確認してください。"
      end

      def run_helper_container!(name_suffix:, mounts:, command:)
        container_id = create_helper_container!(name_suffix: name_suffix, mounts: mounts, command: command)

        docker_client.start_container(id: container_id)
        result = docker_client.wait_container(id: container_id)
        return if result.fetch("StatusCode", 1).to_i.zero?

        logs = docker_client.container_logs(id: container_id, tail: 200)
        raise HelperCommandFailedError, logs.presence || "helper container exited with status #{result.fetch('StatusCode')}"
      ensure
        docker_client.remove_container(id: container_id, force: true) if container_id.present?
      end

      def create_helper_container!(name_suffix:, mounts:, command:)
        docker_client.create_container(
          name: helper_container_name(name_suffix),
          image: helper_image,
          mounts: mounts,
          labels: helper_labels,
          memory_mb: HELPER_MEMORY_MB,
          command: command,
          restart_policy_name: "no",
        ).fetch("Id")
      rescue DockerEngine::NotFoundError => error
        raise unless missing_image_error?(error)

        docker_client.pull_image(image: helper_image)
        retry
      end

      def helper_container_name(name_suffix)
        "mc-world-transfer-#{server.id}-#{name_suffix}-#{request_id}"
      end

      def helper_labels
        DockerEngine::ManagedLabels.for_server(minecraft_server: server).merge(
          "component" => "world-transfer",
        )
      end

      def stage_mount(read_only: false)
        {
          Type: "bind",
          Source: staging_directory.to_s,
          Target: "/staging",
          ReadOnly: read_only,
        }
      end

      def managed_volume_mount(target:, read_only:)
        {
          Type: "volume",
          Source: server.volume_name,
          Target: target,
          ReadOnly: read_only,
        }
      end

      def sync_server_state!
        Servers::SyncServerState.new(server: server, docker_client: docker_client).call
      end

      def ensure_server_stopped!
        stopped_container_states = %w[created exited]
        return if server.status_stopped? && stopped_container_states.include?(server.container_state.to_s)

        raise ServerNotStoppedError, "ワールド転送は停止中サーバーだけ実行できます。先にサーバーを停止して状態を同期してください。"
      end

      def ensure_managed_volume!
        raise MissingManagedVolumeError, "managed volume name is required for world transfer" if server.volume_name.blank?

        inspection = docker_client.inspect_volume(name: server.volume_name)
        labels = inspection.fetch("Labels", {})
        expected_labels = DockerEngine::ManagedLabels.for_server(minecraft_server: server)
        return if expected_labels.all? { |key, value| labels[key].to_s == value.to_s }

        raise MissingManagedVolumeError, "managed world transfer is only allowed for app-owned Docker volumes"
      end

      def missing_image_error?(error)
        error.message.to_s.start_with?("No such image:")
      end
  end
end
