require "test_helper"

class ExecutionProvider::ConfigurationTest < ActiveSupport::TestCase
  test "defaults pterodactyl provider to the placeholder client class" do
    configuration = ExecutionProvider::Configuration.new(provider_name: "pterodactyl")

    assert_equal "ExecutionProvider::PterodactylClient", configuration.client_class_name
    assert_equal ExecutionProvider::PterodactylClient, configuration.client_class
  end

  test "rejects unknown providers" do
    error = assert_raises(ExecutionProvider::UnsupportedProviderError) do
      ExecutionProvider::Configuration.new(provider_name: "unknown-provider")
    end

    assert_equal "unsupported execution provider: unknown-provider", error.message
  end

  test "builds provider create payload from the normalized request object" do
    request = ExecutionProvider::CreateServerRequest.new(
      name: "Sky Lab",
      external_id: "minecraft-server-12",
      owner_id: 10,
      node_id: 2,
      egg_id: 5,
      allocation_id: 21,
      memory_mb: 4096,
      swap_mb: 0,
      disk_mb: 20480,
      io_weight: 500,
      cpu_limit: 150,
      cpu_pinning: "0-1",
      oom_killer_enabled: true,
      allocation_limit: 0,
      backup_limit: 2,
      database_limit: 0,
      environment: { server_jarfile: "paper.jar", minecraft_version: "1.21.4" },
      skip_scripts: true,
    )

    payload = request.to_provider_payload

    assert_equal "Sky Lab", payload[:name]
    assert_equal "minecraft-server-12", payload[:external_id]
    assert_equal 21, payload.dig(:allocation, :default)
    assert_equal 4096, payload.dig(:limits, :memory)
    assert_equal "0-1", payload.dig(:limits, :threads)
    assert_equal true, payload.dig(:limits, :oom_killer)
    assert_equal 2, payload.dig(:feature_limits, :backups)
    assert_equal({ "server_jarfile" => "paper.jar", "minecraft_version" => "1.21.4" }, payload[:environment])
    assert_equal true, payload[:skip_scripts]
  end

  test "rejects invalid create request payloads" do
    error = assert_raises(ExecutionProvider::ValidationError) do
      ExecutionProvider::CreateServerRequest.new(
        name: " ",
        owner_id: 10,
        node_id: 2,
        egg_id: 5,
        allocation_id: 21,
        memory_mb: 4096,
        disk_mb: 20480,
        environment: {},
      )
    end

    assert_equal "name is required", error.message
  end

  test "build_client uses the configured provider class" do
    client = ExecutionProvider.build_client

    assert_instance_of ExecutionProvider::PterodactylClient, client
    assert_equal "pterodactyl", client.configuration.provider_name
    assert_equal ExecutionProvider.config.to_h, client.configuration.to_h
  end
end
