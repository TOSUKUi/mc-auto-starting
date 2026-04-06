module Servers
  class ExportWorld < WorldTransferOperation
    Result = Data.define(:content_type, :data, :filename, :warning)

    def call
      prepare_transfer!
      create_staging_directory!

      run_helper_container!(
        name_suffix: "export",
        mounts: [
          managed_volume_mount(target: "/source", read_only: true),
          stage_mount,
        ],
        command: [ "sh", "-lc", "tar -czf /staging/#{archive_filename} -C /source ." ],
      )

      archive_path = staging_directory.join(archive_filename)
      raise Error, "ワールドアーカイブの生成に失敗しました。" unless archive_path.exist?

      Result.new(
        content_type: "application/gzip",
        data: File.binread(archive_path),
        filename: archive_filename,
        warning: cleanup_staging_directory!,
      )
    rescue StandardError
      cleanup_staging_directory!
      raise
    end

    private
      def archive_filename
        @archive_filename ||= "#{server.hostname}-world-#{Time.current.utc.strftime('%Y%m%d%H%M%S')}.tar.gz"
      end
  end
end
