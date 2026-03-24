require "json"
require "net/http"
require "test_helper"

class ExecutionProvider::PterodactylClientTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:code, :body)
  FakeHttp = Struct.new(:requests, :response) do
    def request(request)
      requests << request
      response
    end
  end

  setup do
    @configuration = ExecutionProvider::Configuration.new(
      provider_name: "pterodactyl",
      panel_url: "https://panel.example.test",
      application_api_key: "ptla_app_key",
      client_api_key: "ptlc_client_key",
      open_timeout: 7,
      read_timeout: 11,
      write_timeout: 13,
    )
    @client = ExecutionProvider::PterodactylClient.new(configuration: @configuration)
  end

  test "create_server posts to application api and returns normalized provider server" do
    request = ExecutionProvider::CreateServerRequest.new(
      name: "Sky Lab",
      owner_id: 10,
      node_id: 2,
      egg_id: 5,
      allocation_id: 21,
      memory_mb: 4096,
      disk_mb: 20480,
      environment: { minecraft_version: "1.21.4", server_jarfile: "paper.jar" },
    )

    created_server = with_stubbed_http(json_response({
      attributes: {
        id: 321,
        identifier: "abcd1234",
        name: "Sky Lab",
        node: 2,
        relationships: {
          allocations: {
            data: [
              {
                attributes: {
                  id: 21,
                  ip: "10.0.0.12",
                  ip_alias: "wings.internal",
                  port: 25565,
                  is_default: true,
                },
              },
            ],
          },
        },
      },
    })) do |requests, connection_args|
      server = @client.create_server(request)

      assert_equal "321", server.provider_server_id
      assert_equal "abcd1234", server.identifier
      assert_equal "wings.internal", server.backend_host
      assert_equal 25565, server.backend_port
      assert_equal 21, server.allocation_id
      assert_equal 2, server.node_id

      assert_equal [ "panel.example.test", 443 ], connection_args[:value].first(2)
      assert_equal true, connection_args[:value][2][:use_ssl]
      assert_equal 7, connection_args[:value][2][:open_timeout]
      assert_equal 11, connection_args[:value][2][:read_timeout]
      assert_equal 13, connection_args[:value][2][:write_timeout]

      http_request = requests.fetch(0)
      assert_instance_of Net::HTTP::Post, http_request
      assert_equal "/api/application/servers", http_request.path
      assert_equal "Bearer ptla_app_key", http_request["Authorization"]
      assert_equal "application/json", http_request["Content-Type"]
      assert_equal "Sky Lab", JSON.parse(http_request.body).fetch("name")
      assert_equal 21, JSON.parse(http_request.body).dig("allocation", "default")

      server
    end

    assert_instance_of ExecutionProvider::ProviderServer, created_server
  end

  test "delete_server hits the application api delete endpoint" do
    deleted = with_stubbed_http(FakeResponse.new("204", "")) do |requests|
      @client.delete_server("srv-001")

      http_request = requests.fetch(0)
      assert_instance_of Net::HTTP::Delete, http_request
      assert_equal "/api/application/servers/srv-001", http_request.path
      assert_equal "Bearer ptla_app_key", http_request["Authorization"]
    end

    assert_equal true, deleted
  end

  test "start stop and restart send client power signals" do
    %w[start stop restart].each do |signal|
      result = with_stubbed_http(FakeResponse.new("204", "")) do |requests|
        lifecycle_result = @client.public_send("#{signal}_server", "srv-001")

        http_request = requests.fetch(0)
        assert_instance_of Net::HTTP::Post, http_request
        assert_equal "/api/client/servers/srv-001/power", http_request.path
        assert_equal "Bearer ptlc_client_key", http_request["Authorization"]
        assert_equal signal, JSON.parse(http_request.body).fetch("signal")

        lifecycle_result
      end

      assert_equal "srv-001", result.provider_server_id
      assert_equal signal, result.action
      assert_equal true, result.accepted
    end
  end

  test "fetch_server uses application api and falls back to allocation ip" do
    server = with_stubbed_http(json_response({
      attributes: {
        id: 111,
        identifier: "server111",
        name: "Vanilla",
        node: 9,
        relationships: {
          allocations: {
            data: [
              {
                attributes: {
                  id: 55,
                  ip: "10.20.30.40",
                  port: 25566,
                  is_default: false,
                },
              },
            ],
          },
        },
      },
    })) do |requests|
      fetched = @client.fetch_server("srv-111")

      http_request = requests.fetch(0)
      assert_instance_of Net::HTTP::Get, http_request
      assert_equal "/api/application/servers/srv-111", http_request.path

      fetched
    end

    assert_equal "10.20.30.40", server.backend_host
    assert_equal 25566, server.backend_port
    assert_equal "111", server.provider_server_id
  end

  test "fetch_status maps pterodactyl states to rails statuses" do
    status = with_stubbed_http(json_response({
      attributes: {
        current_state: "running",
        resources: { memory_bytes: 1024 },
      },
    })) do |requests|
      fetched = @client.fetch_status("abcd1234")

      http_request = requests.fetch(0)
      assert_instance_of Net::HTTP::Get, http_request
      assert_equal "/api/client/servers/abcd1234/resources", http_request.path

      fetched
    end

    assert_equal "running", status.state
    assert_equal "ready", status.rails_status
    assert_equal "abcd1234", status.provider_server_id
  end

  test "unknown provider runtime state degrades rails status" do
    status = with_stubbed_http(json_response({
      attributes: {
        current_state: "crashed",
      },
    })) do
      @client.fetch_status("srv-404")
    end

    assert_equal "degraded", status.rails_status
  end

  test "maps provider errors to domain exceptions" do
    error = assert_raises(ExecutionProvider::AuthenticationError) do
      with_stubbed_http(json_response({
        errors: [
          { detail: "Invalid credentials" },
        ],
      }, code: "401")) do
        @client.fetch_server("srv-401")
      end
    end

    assert_equal "Invalid credentials", error.message
  end

  test "raises validation error when required config is missing" do
    client = ExecutionProvider::PterodactylClient.new(
      configuration: @configuration.with_overrides(panel_url: nil),
    )

    error = assert_raises(ExecutionProvider::ValidationError) do
      client.fetch_server("srv-001")
    end

    assert_equal "execution provider panel_url is required", error.message
  end

  private
    def with_stubbed_http(response)
      requests = []
      connection_args = {}
      http_singleton = Net::HTTP.singleton_class
      original_start = Net::HTTP.method(:start)

      http_singleton.send(:define_method, :start) do |host, port, **options, &block|
        connection_args[:value] = [ host, port, options ]
        block.call(FakeHttp.new(requests, response))
      end

      result = block_given? ? yield(requests, connection_args) : nil
      result
    ensure
      http_singleton.send(:define_method, :start, original_start)
    end

    def json_response(payload, code: "200")
      FakeResponse.new(code, JSON.generate(payload))
    end
end
