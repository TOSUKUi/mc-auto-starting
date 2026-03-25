require "test_helper"

class DockerEngine::ConnectionTest < ActiveSupport::TestCase
  FakeRawResponse = Struct.new(:status, :headers, :body, keyword_init: true)

  FakeExconConnection = Struct.new(:response_or_error, :requests, keyword_init: true) do
    def request(**options)
      requests << options
      raise response_or_error if response_or_error.is_a?(Exception)

      response_or_error
    end
  end

  setup do
    @configuration = DockerEngine::Configuration.new(
      socket_path: "/var/run/docker.sock",
      api_version: "v1.51",
      open_timeout: 5,
      read_timeout: 30,
      write_timeout: 30,
    )
  end

  test "encodes json requests and decodes json responses" do
    fake_connection = FakeExconConnection.new(
      response_or_error: FakeRawResponse.new(
        status: 201,
        headers: { "Content-Type" => "application/json" },
        body: JSON.generate({ "Id" => "container-001" }),
      ),
      requests: [],
    )

    response = DockerEngine::Connection.new(
      configuration: @configuration,
      excon_connection: fake_connection,
    ).request(
      method: :post,
      path: "/containers/create",
      body: { Image: "itzg/minecraft-server" },
    )

    request = fake_connection.requests.fetch(0)
    assert_equal "POST", request.fetch(:method)
    assert_equal "/v1.51/containers/create", request.fetch(:path)
    assert_equal "application/json", request.fetch(:headers).fetch("Content-Type")
    assert_equal({ "Id" => "container-001" }, response.body)
  end

  test "keeps ping unversioned and returns raw text bodies" do
    fake_connection = FakeExconConnection.new(
      response_or_error: FakeRawResponse.new(status: 200, headers: { "Content-Type" => "text/plain" }, body: "OK"),
      requests: [],
    )

    response = DockerEngine::Connection.new(
      configuration: @configuration,
      excon_connection: fake_connection,
    ).request(method: :get, path: "/_ping", versioned: false)

    assert_equal "/_ping", fake_connection.requests.fetch(0).fetch(:path)
    assert_equal "OK", response.body
  end

  test "maps http errors to domain exceptions" do
    fake_connection = FakeExconConnection.new(
      response_or_error: FakeRawResponse.new(
        status: 404,
        headers: { "Content-Type" => "application/json" },
        body: JSON.generate({ "message" => "No such container" }),
      ),
      requests: [],
    )

    error = assert_raises(DockerEngine::NotFoundError) do
      DockerEngine::Connection.new(configuration: @configuration, excon_connection: fake_connection).request(
        method: :get,
        path: "/containers/missing/json",
      )
    end

    assert_equal 404, error.status
    assert_equal "No such container", error.message
  end

  test "uses unversioned paths when api_version is blank" do
    fake_connection = FakeExconConnection.new(
      response_or_error: FakeRawResponse.new(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: JSON.generate({ "Version" => "1.44" }),
      ),
      requests: [],
    )

    configuration = DockerEngine::Configuration.new(socket_path: "/var/run/docker.sock")

    DockerEngine::Connection.new(
      configuration: configuration,
      excon_connection: fake_connection,
    ).request(method: :get, path: "/version")

    assert_equal "/version", fake_connection.requests.fetch(0).fetch(:path)
  end
end
