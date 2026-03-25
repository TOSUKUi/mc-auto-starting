require "test_helper"

class DockerEngine::ConfigurationTest < ActiveSupport::TestCase
  test "casts timeout values and supports overrides" do
    configuration = DockerEngine::Configuration.new(
      socket_path: "/var/run/docker.sock",
      api_version: "/v1.51",
      open_timeout: "7",
      read_timeout: "11",
      write_timeout: "13",
    )

    overridden = configuration.with_overrides(api_version: "v1.52", read_timeout: 22)

    assert_equal "/var/run/docker.sock", configuration.socket_path
    assert_equal "v1.51", configuration.api_version
    assert_equal 7, configuration.open_timeout
    assert_equal 11, configuration.read_timeout
    assert_equal 13, configuration.write_timeout
    assert_equal "v1.52", overridden.api_version
    assert_equal 22, overridden.read_timeout
  end
end
