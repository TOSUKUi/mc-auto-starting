require "test_helper"

class Servers::DestroyServerTest < ActiveSupport::TestCase
  FakeDockerClient = Struct.new(:calls, :container_error, :volume_error, keyword_init: true) do
    def remove_container(**kwargs)
      calls << [ :remove_container, kwargs ]
      raise container_error if container_error

      true
    end

    def remove_volume(**kwargs)
      calls << [ :remove_volume, kwargs ]
      raise volume_error if volume_error

      true
    end
  end

  FakeRouterApplier = Struct.new(:calls) do
    def call(routes:)
      calls << routes
      Router::ConfigApplier::ApplyResult.new(path: "/tmp/routes.json", reload_strategy: "watch", reloaded: true)
    end
  end

  test "unpublishes the route, deletes Docker resources, and removes the record" do
    server = minecraft_servers(:one)
    router_applier = FakeRouterApplier.new([])
    docker_client = FakeDockerClient.new(calls: [])

    assert_difference("MinecraftServer.count", -1) do
      assert_difference("RouterRoute.count", -1) do
        Servers::DestroyServer.new(
          server: server,
          docker_client: docker_client,
          router_applier: router_applier,
        ).call
      end
    end

    assert_equal(
      [
        [ :remove_container, { id: "container-001", force: true } ],
        [ :remove_volume, { name: "mc-data-main-survival" } ],
      ],
      docker_client.calls,
    )
    assert_equal 1, router_applier.calls.size
    assert_not MinecraftServer.exists?(server.id)
  end

  test "tolerates missing managed container and volume during delete" do
    server = minecraft_servers(:one)
    router_applier = FakeRouterApplier.new([])
    docker_client = FakeDockerClient.new(
      calls: [],
      container_error: DockerEngine::NotFoundError.new("container missing", status: 404, body: {}),
      volume_error: DockerEngine::NotFoundError.new("volume missing", status: 404, body: {}),
    )

    assert_difference("MinecraftServer.count", -1) do
      assert_difference("RouterRoute.count", -1) do
        Servers::DestroyServer.new(
          server: server,
          docker_client: docker_client,
          router_applier: router_applier,
        ).call
      end
    end

    assert_equal 2, docker_client.calls.size
  end

  test "keeps the deleting record when Docker cleanup fails after route unpublish" do
    server = minecraft_servers(:one)
    router_applier = FakeRouterApplier.new([])
    docker_error = DockerEngine::RequestError.new("delete failed")

    assert_no_difference("MinecraftServer.count") do
      assert_no_difference("RouterRoute.count") do
        assert_raises(DockerEngine::RequestError) do
          Servers::DestroyServer.new(
            server: server,
            docker_client: FakeDockerClient.new(calls: [], container_error: docker_error),
            router_applier: router_applier,
          ).call
        end
      end
    end

    server.reload

    assert_equal "deleting", server.status
    assert_equal false, server.router_route.enabled
    assert_equal "success", server.router_route.last_apply_status
    assert_not_nil server.router_route.last_applied_at
    assert_equal "delete failed", server.last_error_message
  end
end
