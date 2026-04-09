require "fileutils"
require "pathname"
require "zip"

module Servers
  class WorldArchiveValidator
    MAX_COMPRESSED_BYTES = 5.gigabytes
    MAX_EXPANDED_BYTES = 10.gigabytes

    Result = Data.define(:expanded_bytes, :file_count)

    def initialize(archive_path:, extraction_root:)
      @archive_path = Pathname.new(archive_path)
      @extraction_root = Pathname.new(extraction_root)
    end

    def call
      validate_compressed_size!
      FileUtils.mkdir_p(extraction_root)

      expanded_bytes = 0
      file_count = 0

      Zip::File.open(archive_path.to_s) do |zip_file|
        zip_file.each do |entry|
          relative_path = normalize_entry_path(entry.name)
          next if relative_path.nil?

          destination = extraction_root.join(relative_path)

          if entry.directory?
            FileUtils.mkdir_p(destination)
            next
          end

          unless entry.file?
            raise WorldTransferOperation::InvalidArchiveError, "安全でないアーカイブ項目が含まれています: #{entry.name}"
          end

          expanded_bytes += entry.size.to_i
          if expanded_bytes > MAX_EXPANDED_BYTES
            raise WorldTransferOperation::InvalidArchiveError, "展開後サイズが上限 10 GiB を超えています。"
          end

          FileUtils.mkdir_p(destination.dirname)
          entry.get_input_stream do |input_stream|
            File.open(destination, "wb") do |file|
              IO.copy_stream(input_stream, file)
            end
          end
          file_count += 1
        end
      end

      if file_count.zero?
        raise WorldTransferOperation::InvalidArchiveError, "空のアーカイブはアップロードできません。"
      end

      Result.new(expanded_bytes: expanded_bytes, file_count: file_count)
    rescue Zip::Error, EOFError => error
      raise WorldTransferOperation::InvalidArchiveError, "アーカイブを安全に解析できませんでした: #{error.message}"
    end

    private
      attr_reader :archive_path, :extraction_root

      def validate_compressed_size!
        if archive_path.size > MAX_COMPRESSED_BYTES
          raise WorldTransferOperation::InvalidArchiveError, "アップロードサイズが上限 5 GiB を超えています。"
        end
      end

      def normalize_entry_path(raw_path)
        path = raw_path.to_s.delete_prefix("./")
        return nil if path.blank? || path == "."

        pathname = Pathname.new(path)
        if pathname.absolute? || pathname.each_filename.any? { |segment| segment.blank? || segment == ".." }
          raise WorldTransferOperation::InvalidArchiveError, "相対パスではない項目が含まれています: #{raw_path}"
        end

        pathname.to_s
      end
  end
end
