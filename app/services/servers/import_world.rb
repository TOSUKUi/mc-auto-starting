require "fileutils"

module Servers
  class ImportWorld < WorldTransferOperation
    Result = Data.define(:warning)

    def initialize(server:, uploaded_file:, **kwargs)
      super(server: server, **kwargs)
      @uploaded_file = uploaded_file
    end

    def call
      prepare_transfer!
      create_staging_directory!
      validate_uploaded_file!
      persist_uploaded_archive!
      extract_uploaded_archive!

      run_helper_container!(
        name_suffix: "import",
        mounts: [
          {
            Type: "bind",
            Source: validated_directory.to_s,
            Target: "/incoming",
            ReadOnly: true,
          },
          managed_volume_mount(target: "/target", read_only: false),
        ],
        command: [ "sh", "-lc", "find /target -mindepth 1 -exec rm -rf -- {} + && cp -a /incoming/. /target/" ],
      )

      Result.new(warning: cleanup_staging_directory!)
    rescue StandardError
      cleanup_staging_directory!
      raise
    end

    private
      attr_reader :uploaded_file

      def staged_archive_path
        staging_directory.join("upload.zip")
      end

      def validated_directory
        staging_directory.join("validated")
      end

      def validate_uploaded_file!
        if uploaded_file.blank?
          raise InvalidArchiveError, "アップロードする `.zip` を選択してください。"
        end

        filename = uploaded_file.original_filename.to_s
        return if filename.end_with?(".zip")

        raise InvalidArchiveError, "アップロードできるのは `.zip` 形式だけです。"
      end

      def persist_uploaded_archive!
        uploaded_file.tempfile.rewind if uploaded_file.respond_to?(:tempfile) && uploaded_file.tempfile.respond_to?(:rewind)
        IO.copy_stream(uploaded_io, staged_archive_path.to_s)
      end

      def extract_uploaded_archive!
        WorldArchiveValidator.new(
          archive_path: staged_archive_path,
          extraction_root: validated_directory,
        ).call
      end

      def uploaded_io
        return uploaded_file.tempfile if uploaded_file.respond_to?(:tempfile)

        uploaded_file
      end
  end
end
