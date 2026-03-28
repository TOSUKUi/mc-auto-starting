require "test_helper"

class Servers::LifecycleOperationTest < ActiveSupport::TestCase
  FakeDockerClient = Struct.new(:calls, :inspect_result, :created_container_id, :error, keyword_init: true) do
    def remove_container(**kwargs)
      calls << [ :remove_container, kwargs ]
      raise error if error

      true
    end

    def create_container(**kwargs)
      calls << [ :create_container, kwargs ]
      raise error if error

      { "Id" => created_container_id || inspect_result.fetch("Id") }
    end

    def pull_image(**kwargs)
      calls << [ :pull_image, kwargs ]
      raise error if error

      true
    end

    def start_container(**kwargs)
      calls << [ :start_container, kwargs ]
      raise error if error

      true
    end

    def stop_container(**kwargs)
      calls << [ :stop_container, kwargs ]
      raise error if error

      true
    end

    def restart_container(**kwargs)
      calls << [ :restart_container, kwargs ]
      raise error if error

      true
    end

    def inspect_container(**kwargs)
      calls << [ :inspect_container, kwargs ]
      raise error if error

      inspect_result
    end
  end

  test "start uses the managed container reference and marks the server starting" do
    server = minecraft_servers(:one)
    server.update_columns(status: "stopped", container_state: "exited")
    docker_client = FakeDockerClient.new(
      calls: [],
      created_container_id: "container-002",
      inspect_result: {
        "Id" => "container-002",
        "State" => { "Status" => "running" },
      },
    )

    result = Servers::StartServer.new(server: server, docker_client: docker_client).call

    assert_equal server, result
    assert_equal [ :remove_container, { id: "container-001", force: false } ], docker_client.calls.fetch(0)
    assert_equal :create_container, docker_client.calls.fetch(1).fetch(0)
    assert_equal [ :start_container, { id: "container-002" } ], docker_client.calls.fetch(2)
    assert_equal [ :inspect_container, { id_or_name: "container-002" } ], docker_client.calls.fetch(3)
    assert_equal "starting", server.reload.status
    assert_equal "running", server.container_state
    assert_equal "container-002", server.container_id
    assert_not_nil server.last_started_at
    assert_nil server.last_error_message
  end

  test "stop uses the managed container reference and marks the server stopping" do
    server = minecraft_servers(:one)
    docker_client = FakeDockerClient.new(
      calls: [],
      inspect_result: {
        "Id" => "container-001",
        "State" => { "Status" => "exited" },
      },
    )

    Servers::StopServer.new(server: server, docker_client: docker_client).call

    assert_equal [ :stop_container, { id: "container-001", timeout_seconds: 30 } ], docker_client.calls.fetch(0)
    assert_equal [ :inspect_container, { id_or_name: "container-001" } ], docker_client.calls.fetch(1)
    assert_equal "stopping", server.reload.status
    assert_equal "exited", server.container_state
  end

  test "restart recreates the container with the managed reference and marks the server restarting" do
    server = minecraft_servers(:one)
    server.update_columns(status: "ready", container_state: "running")
    docker_client = FakeDockerClient.new(
      calls: [],
      created_container_id: "container-003",
      inspect_result: {
        "Id" => "container-003",
        "State" => { "Status" => "running" },
      },
    )

    Servers::RestartServer.new(server: server, docker_client: docker_client).call

    assert_equal [ :stop_container, { id: "container-001", timeout_seconds: 30 } ], docker_client.calls.fetch(0)
    assert_equal [ :remove_container, { id: "container-001", force: false } ], docker_client.calls.fetch(1)
    assert_equal :create_container, docker_client.calls.fetch(2).fetch(0)
    assert_equal [ :start_container, { id: "container-003" } ], docker_client.calls.fetch(3)
    assert_equal [ :inspect_container, { id_or_name: "container-003" } ], docker_client.calls.fetch(4)
    assert_equal "restarting", server.reload.status
    assert_equal "running", server.container_state
    assert_equal "container-003", server.container_id
    assert_not_nil server.last_started_at
  end

  test "sync maps Docker running state onto the server status" do
    server = minecraft_servers(:one)
    server.update!(status: :stopping, container_state: "stopping")
    docker_client = FakeDockerClient.new(
      calls: [],
      inspect_result: {
        "Id" => "container-001",
        "State" => {
          "Status" => "exited",
          "StartedAt" => "2026-03-25T08:00:00Z",
        },
      },
    )

    Servers::SyncServerState.new(server: server, docker_client: docker_client).call

    assert_equal [ [ :inspect_container, { id_or_name: "container-001" } ] ], docker_client.calls
    assert_equal "stopped", server.reload.status
    assert_equal "exited", server.container_state
    assert_equal Time.zone.parse("2026-03-25T08:00:00Z"), server.last_started_at
    assert_nil server.last_error_message
  end

  test "sync degrades the server on conflicting Docker state" do
    server = minecraft_servers(:one)
    server.update!(status: :restarting)
    docker_client = FakeDockerClient.new(
      calls: [],
      inspect_result: {
        "Id" => "container-001",
        "State" => { "Status" => "exited" },
      },
    )

    Servers::SyncServerState.new(server: server, docker_client: docker_client).call

    assert_equal "degraded", server.reload.status
    assert_equal "exited", server.container_state
  end

  test "sync degrades the server when Docker no longer finds it" do
    server = minecraft_servers(:one)
    docker_client = FakeDockerClient.new(
      calls: [],
      inspect_result: nil,
      error: DockerEngine::NotFoundError.new("missing", status: 404, body: { "message" => "missing" }),
    )

    Servers::SyncServerState.new(server: server, docker_client: docker_client).call

    assert_equal "degraded", server.reload.status
    assert_nil server.container_id
    assert_nil server.container_state
    assert_equal "missing", server.last_error_message
  end

  test "lifecycle actions require the managed container reference" do
    server = minecraft_servers(:one)
    server.update_columns(container_id: nil, container_name: "")

    error = assert_raises(DockerEngine::ValidationError) do
      Servers::StartServer.new(server: server, docker_client: FakeDockerClient.new(calls: [], inspect_result: {})).call
    end

    assert_equal "managed container reference is required for lifecycle operations", error.message
  end
end
