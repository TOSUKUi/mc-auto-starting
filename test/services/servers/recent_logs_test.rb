require "test_helper"

class Servers::RecentLogsTest < ActiveSupport::TestCase
  FakeClient = Struct.new(:raw_logs, :error, keyword_init: true) do
    def container_logs(id:, tail:, stdout: true, stderr: true, timestamps: false)
      raise error if error

      raw_logs
    end
  end

  test "reads plain text log tails" do
    payload = Servers::RecentLogs.new(
      server: minecraft_servers(:one),
      docker_client: FakeClient.new(raw_logs: "[12:00:01] hello\n[12:00:05] joined\n"),
    ).read(tail: 50)

    assert_equal true, payload.fetch(:available)
    assert_equal [ "[12:00:01] hello", "[12:00:05] joined" ], payload.fetch(:lines)
    assert_equal false, payload.fetch(:truncated)
  end

  test "decodes docker multiplexed frame logs" do
    raw_logs = docker_frame("[12:00:01] line one\n") + docker_frame("[12:00:02] line two\n")
    payload = Servers::RecentLogs.new(
      server: minecraft_servers(:one),
      docker_client: FakeClient.new(raw_logs: raw_logs),
    ).read(tail: 50)

    assert_equal true, payload.fetch(:available)
    assert_equal [ "[12:00:01] line one", "[12:00:02] line two" ], payload.fetch(:lines)
  end

  test "returns unavailable when docker log read fails" do
    payload = Servers::RecentLogs.new(
      server: minecraft_servers(:one),
      docker_client: FakeClient.new(error: DockerEngine::ConnectionError.new("socket failed")),
    ).read

    assert_equal false, payload.fetch(:available)
    assert_equal "logs_unavailable", payload.fetch(:error_code)
  end

  private
    def docker_frame(payload)
      [ 1, 0, 0, 0, payload.bytesize ].pack("C4N") + payload
    end
end
