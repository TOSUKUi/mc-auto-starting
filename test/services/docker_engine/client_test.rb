require "test_helper"

class DockerEngine::ClientTest < ActiveSupport::TestCase
  FakeConnection = Struct.new(:responses, :requests, keyword_init: true) do
    def request(**options)
      requests << options
      responses.shift
    end
  end

  setup do
    @configuration = DockerEngine::Configuration.new(socket_path: "/var/run/docker.sock")
  end

  test "lists managed containers with built-in label filters" do
    connection = FakeConnection.new(
      responses: [ DockerEngine::Response.new(status: 200, headers: {}, body: []) ],
      requests: [],
    )

    DockerEngine::Client.new(configuration: @configuration, connection: connection).list_managed_containers(
      filters: { label: [ "minecraft_server_id=1" ] },
    )

    request = connection.requests.fetch(0)
    assert_equal "/containers/json", request.fetch(:path)
    assert_equal 1, request.fetch(:query).fetch(:all)

    filters = JSON.parse(request.fetch(:query).fetch(:filters))
    assert_equal [ "app=mc-auto-starting", "managed_by=rails", "minecraft_server_id=1" ], filters.fetch("label")
  end

  test "lists containers with raw filters" do
    connection = FakeConnection.new(
      responses: [ DockerEngine::Response.new(status: 200, headers: {}, body: [ { "Id" => "router-123" } ]) ],
      requests: [],
    )

    result = DockerEngine::Client.new(configuration: @configuration, connection: connection).list_containers(
      filters: { label: [ "app.kubos.dev/component=mc-router" ] },
      all: false,
    )

    request = connection.requests.fetch(0)

    assert_equal [ { "Id" => "router-123" } ], result
    assert_equal "/containers/json", request.fetch(:path)
    assert_equal 0, request.fetch(:query).fetch(:all)
    assert_equal [ "app.kubos.dev/component=mc-router" ], JSON.parse(request.fetch(:query).fetch(:filters)).fetch("label")
  end

  test "creates managed volumes with merged labels" do
    connection = FakeConnection.new(
      responses: [ DockerEngine::Response.new(status: 201, headers: {}, body: { "Name" => "mc-data-main-survival" }) ],
      requests: [],
    )

    DockerEngine::Client.new(configuration: @configuration, connection: connection).create_volume(
      name: "mc-data-main-survival",
      labels: { "minecraft_server_hostname" => "main-survival" },
    )

    payload = connection.requests.fetch(0).fetch(:body)
    assert_equal "mc-data-main-survival", payload.fetch(:Name)
    assert_equal "mc-auto-starting", payload.fetch(:Labels).fetch("app")
    assert_equal "main-survival", payload.fetch(:Labels).fetch("minecraft_server_hostname")
  end

  test "creates containers with env mounts labels network and memory" do
    connection = FakeConnection.new(
      responses: [ DockerEngine::Response.new(status: 201, headers: {}, body: { "Id" => "container-001" }) ],
      requests: [],
    )

    DockerEngine::Client.new(configuration: @configuration, connection: connection).create_container(
      name: "mc-server-main-survival",
      image: "itzg/minecraft-server:java21",
      env: { "EULA" => "TRUE", "VERSION" => "1.21.4" },
      mounts: [ { Type: "volume", Source: "mc-data-main-survival", Target: "/data" } ],
      labels: { "minecraft_server_id" => "1" },
      network_name: "mc_router_net",
      memory_mb: 4096,
    )

    request = connection.requests.fetch(0)
    payload = request.fetch(:body)

    assert_equal({ name: "mc-server-main-survival" }, request.fetch(:query))
    assert_equal "itzg/minecraft-server:java21", payload.fetch(:Image)
    assert_equal [ "EULA=TRUE", "VERSION=1.21.4" ], payload.fetch(:Env)
    assert_equal 4_294_967_296, payload.dig(:HostConfig, :Memory)
    assert_equal "mc_router_net", payload.dig(:NetworkingConfig, :EndpointsConfig).keys.first
    assert_equal "mc-auto-starting", payload.fetch(:Labels).fetch("app")
    assert_equal "1", payload.fetch(:Labels).fetch("minecraft_server_id")
  end

  test "pulls images through the engine API" do
    connection = FakeConnection.new(
      responses: [ DockerEngine::Response.new(status: 200, headers: { "content-type" => "application/json" }, body: "{\"status\":\"Pulling from marctv/minecraft-papermc-server\"}\n{\"status\":\"Downloaded newer image\"}") ],
      requests: [],
    )

    assert_equal true, DockerEngine::Client.new(configuration: @configuration, connection: connection).pull_image(
      image: "marctv/minecraft-papermc-server:latest",
    )

    request = connection.requests.fetch(0)
    assert_equal "/images/create", request.fetch(:path)
    assert_equal({ fromImage: "marctv/minecraft-papermc-server:latest" }, request.fetch(:query))
  end

  test "passes lifecycle timeouts and force flags through to the engine" do
    connection = FakeConnection.new(
      responses: [
        DockerEngine::Response.new(status: 204, headers: {}, body: nil),
        DockerEngine::Response.new(status: 204, headers: {}, body: nil),
        DockerEngine::Response.new(status: 204, headers: {}, body: nil),
      ],
      requests: [],
    )
    client = DockerEngine::Client.new(configuration: @configuration, connection: connection)

    assert_equal true, client.stop_container(id: "container-001", timeout_seconds: 15)
    assert_equal true, client.restart_container(id: "container-001", timeout_seconds: 30)
    assert_equal true, client.remove_container(id: "container-001", force: true)

    assert_equal({ t: 15 }, connection.requests.fetch(0).fetch(:query))
    assert_equal({ t: 30 }, connection.requests.fetch(1).fetch(:query))
    assert_equal({ force: 1 }, connection.requests.fetch(2).fetch(:query))
  end

  test "sends signals to containers through the engine" do
    connection = FakeConnection.new(
      responses: [ DockerEngine::Response.new(status: 204, headers: {}, body: nil) ],
      requests: [],
    )

    result = DockerEngine::Client.new(configuration: @configuration, connection: connection).signal_container(
      id: "router-123",
      signal: "HUP",
    )

    request = connection.requests.fetch(0)

    assert_equal true, result
    assert_equal "/containers/router-123/kill", request.fetch(:path)
    assert_equal({ signal: "HUP" }, request.fetch(:query))
  end

  test "reads container logs with bounded tail" do
    connection = FakeConnection.new(
      responses: [ DockerEngine::Response.new(status: 200, headers: { "content-type" => "application/octet-stream" }, body: "log line" ) ],
      requests: [],
    )

    result = DockerEngine::Client.new(configuration: @configuration, connection: connection).container_logs(
      id: "container-001",
      tail: 120,
    )

    request = connection.requests.fetch(0)

    assert_equal "log line", result
    assert_equal "/containers/container-001/logs", request.fetch(:path)
    assert_equal({ stdout: 1, stderr: 1, timestamps: 0, tail: 120 }, request.fetch(:query))
  end
end
