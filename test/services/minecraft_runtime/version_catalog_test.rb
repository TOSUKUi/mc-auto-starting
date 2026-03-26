require "test_helper"

class MinecraftRuntime::VersionCatalogTest < ActiveSupport::TestCase
  FakeHttpClient = Struct.new(:responses, :error, keyword_init: true) do
    def get_json(url)
      raise error if error

      responses.fetch(url)
    end
  end

  test "builds vanilla options from the mojang manifest" do
    cache = ActiveSupport::Cache::MemoryStore.new
    http_client = FakeHttpClient.new(
      responses: {
        MinecraftRuntime.version_source_url(runtime_family: "vanilla") => {
          "latest" => { "release" => "26.1" },
          "versions" => [
            { "id" => "26.1", "type" => "release" },
            { "id" => "26.1-rc-3", "type" => "snapshot" },
            { "id" => "1.21.11", "type" => "release" },
          ],
        },
      },
    )

    options = MinecraftRuntime::VersionCatalog.new(cache: cache, http_client: http_client).version_options(runtime_family: "vanilla")

    assert_equal(
      [
        { value: "latest", label: "26.1 (latest)" },
        { value: "26.1", label: "26.1" },
        { value: "1.21.11", label: "1.21.11" },
      ],
      options,
    )
  end

  test "builds paper options from the paper source and excludes prereleases" do
    cache = ActiveSupport::Cache::MemoryStore.new
    http_client = FakeHttpClient.new(
      responses: {
        MinecraftRuntime.version_source_url(runtime_family: "paper") => {
          "latest" => "1.21.11",
          "versions" => {
            "1.21.11" => "https://example.test/paper-1.21.11.jar",
            "1.21.11-rc3" => "https://example.test/paper-1.21.11-rc3.jar",
            "1.21.10" => "https://example.test/paper-1.21.10.jar",
          },
        },
      },
    )

    options = MinecraftRuntime::VersionCatalog.new(cache: cache, http_client: http_client).version_options(runtime_family: "paper")

    assert_equal(
      [
        { value: "latest", label: "1.21.11 (latest)" },
        { value: "1.21.11", label: "1.21.11" },
        { value: "1.21.10", label: "1.21.10" },
      ],
      options,
    )
  end

  test "falls back to the checked-in catalog when the upstream fetch fails" do
    cache = ActiveSupport::Cache::MemoryStore.new
    http_client = FakeHttpClient.new(error: SocketError.new("dns failure"))

    options = MinecraftRuntime::VersionCatalog.new(cache: cache, http_client: http_client).version_options(runtime_family: "paper")

    assert_equal MinecraftRuntime.fallback_version_options(runtime_family: "paper"), options
  end
end
