require "test_helper"
require "rubygems/package"
require "tempfile"
require "zlib"

class Servers::WorldTransferTest < ActiveSupport::TestCase
  FakeDockerClient = Struct.new(:server, :created_container, :removed_container_ids, :captured_incoming_entries, keyword_init: true) do
    def inspect_container(id_or_name:)
      {
        "Id" => server.container_id,
        "State" => {
          "Status" => server.container_state,
          "StartedAt" => "2026-04-07T00:00:00Z",
        },
      }
    end

    def inspect_volume(name:)
      {
        "Name" => name,
        "Labels" => DockerEngine::ManagedLabels.for_server(minecraft_server: server),
      }
    end

    def create_container(**kwargs)
      self.created_container = kwargs
      { "Id" => "helper-001" }
    end

    def start_container(id:)
      mounts = created_container.fetch(:mounts)
      command = created_container.fetch(:command).last

      if command.include?("/staging/")
        stage_dir = mounts.find { |mount| mount[:Target] == "/staging" }.fetch(:Source)
        archive_name = command.match(%r{/staging/([^\s]+\.tar\.gz)})[1]
        File.binwrite(File.join(stage_dir, archive_name), "archive-body")
      else
        incoming_dir = mounts.find { |mount| mount[:Target] == "/incoming" }.fetch(:Source)
        self.captured_incoming_entries = Dir.glob(File.join(incoming_dir, "**", "*"), File::FNM_DOTMATCH)
          .reject { |path| [ ".", ".." ].include?(File.basename(path)) }
          .map { |path| path.delete_prefix("#{incoming_dir}/") }
          .sort
      end

      true
    end

    def wait_container(id:)
      { "StatusCode" => 0 }
    end

    def remove_container(id:, force: false)
      removed_container_ids << id
      true
    end

    def container_logs(id:, tail:, stdout: true, stderr: true, timestamps: false)
      ""
    end

    def pull_image(image:)
      true
    end
  end

  test "export writes an archive through a helper container and cleans staging" do
    server = minecraft_servers(:one)
    server.update_columns(status: MinecraftServer.statuses.fetch(:stopped), container_state: "exited")
    staging_root = Rails.root.join("tmp/world_transfer_test_export")
    docker_client = FakeDockerClient.new(server: server, removed_container_ids: [])

    result = Servers::ExportWorld.new(
      server: server,
      docker_client: docker_client,
      request_id: "export-request",
      staging_root: staging_root,
    ).call

    assert_equal "application/gzip", result.content_type
    assert_equal "archive-body", result.data
    assert_match(/\Amain-survival-world-\d{14}\.tar\.gz\z/, result.filename)
    assert_equal [ "helper-001" ], docker_client.removed_container_ids
    assert_equal false, staging_root.join("export-request").exist?
  ensure
    FileUtils.rm_rf(staging_root) if staging_root
  end

  test "import extracts validated contents and copies them through a helper container" do
    server = minecraft_servers(:one)
    server.update_columns(status: MinecraftServer.statuses.fetch(:stopped), container_state: "exited")
    staging_root = Rails.root.join("tmp/world_transfer_test_import")
    docker_client = FakeDockerClient.new(server: server, removed_container_ids: [])
    upload = Rack::Test::UploadedFile.new(
      build_world_archive("world/level.dat" => "seed-data", "server.properties" => "motd=test"),
      "application/gzip",
      original_filename: "world-backup.tar.gz",
    )

    result = Servers::ImportWorld.new(
      server: server,
      uploaded_file: upload,
      docker_client: docker_client,
      request_id: "import-request",
      staging_root: staging_root,
    ).call

    assert_nil result.warning
    assert_equal [ "helper-001" ], docker_client.removed_container_ids
    assert_includes docker_client.captured_incoming_entries, "world/level.dat"
    assert_includes docker_client.captured_incoming_entries, "server.properties"
    assert_equal false, staging_root.join("import-request").exist?
  ensure
    FileUtils.rm_rf(staging_root) if staging_root
  end

  test "import rejects archives with path traversal" do
    server = minecraft_servers(:one)
    server.update_columns(status: MinecraftServer.statuses.fetch(:stopped), container_state: "exited")
    staging_root = Rails.root.join("tmp/world_transfer_test_invalid")
    docker_client = FakeDockerClient.new(server: server, removed_container_ids: [])
    upload = Rack::Test::UploadedFile.new(
      build_world_archive("../escape.txt" => "nope"),
      "application/gzip",
      original_filename: "world-backup.tar.gz",
    )

    error = assert_raises(Servers::WorldTransferOperation::InvalidArchiveError) do
      Servers::ImportWorld.new(
        server: server,
        uploaded_file: upload,
        docker_client: docker_client,
        request_id: "invalid-request",
        staging_root: staging_root,
      ).call
    end

    assert_match(/相対パスではない項目/, error.message)
  ensure
    FileUtils.rm_rf(staging_root) if staging_root
  end

  private
    def build_world_archive(entries)
      file = Tempfile.new([ "world-transfer", ".tar.gz" ])
      file.binmode

      Zlib::GzipWriter.wrap(file) do |gzip|
        Gem::Package::TarWriter.new(gzip) do |tar|
          entries.each do |path, contents|
            tar.mkdir(File.dirname(path), 0o755) unless File.dirname(path) == "."
            tar.add_file_simple(path, 0o644, contents.bytesize) do |io|
              io.write(contents)
            end
          end
        end
      end

      file.close
      file.path
    end
end
