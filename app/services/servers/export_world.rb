require "pathname"
require "find"
require "zip"

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
        command: [ "sh", "-lc", "mkdir -p /staging/export-root && tar -cf - -C /source . | tar -xf - -C /staging/export-root" ],
      )

      create_zip_archive!
      archive_path = staging_directory.join(archive_filename)
      raise Error, "ワールドアーカイブの生成に失敗しました。" unless archive_path.exist?

      Result.new(
        content_type: "application/zip",
        data: File.binread(archive_path),
        filename: archive_filename,
        warning: cleanup_staging_directory!,
      )
    rescue StandardError
      cleanup_staging_directory!
      raise
    end

    private
      def export_root_directory
        staging_directory.join("export-root")
      end

      def create_zip_archive!
        Zip::File.open(staging_directory.join(archive_filename).to_s, create: true) do |zip_file|
          Find.find(export_root_directory.to_s) do |path|
            next if path == export_root_directory.to_s

            relative_path = Pathname.new(path).relative_path_from(export_root_directory).to_s

            if File.directory?(path)
              zip_file.mkdir(relative_path) unless zip_file.find_entry(relative_path)
              next
            end

            zip_file.get_output_stream(relative_path) do |output_stream|
              File.open(path, "rb") do |input_file|
                IO.copy_stream(input_file, output_stream)
              end
            end
          end
        end
      end

      def archive_filename
        @archive_filename ||= "#{server.hostname}-world-#{Time.current.utc.strftime('%Y%m%d%H%M%S')}.zip"
      end
  end
end
