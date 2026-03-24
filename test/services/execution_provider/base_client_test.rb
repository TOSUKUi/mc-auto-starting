require "test_helper"

class ExecutionProvider::BaseClientTest < ActiveSupport::TestCase
  setup do
    @configuration = ExecutionProvider::Configuration.new(provider_name: "pterodactyl")
    @client = ExecutionProvider::BaseClient.new(configuration: @configuration)
  end

  test "raises for abstract create_server contract" do
    error = assert_raises(NotImplementedError) { @client.create_server(Object.new) }

    assert_equal "ExecutionProvider::BaseClient must implement #create_server", error.message
  end

  test "raises for abstract lifecycle and lookup methods" do
    assert_raises(NotImplementedError) { @client.delete_server("srv-001") }
    assert_raises(NotImplementedError) { @client.start_server("srv-001") }
    assert_raises(NotImplementedError) { @client.stop_server("srv-001") }
    assert_raises(NotImplementedError) { @client.restart_server("srv-001") }
    assert_raises(NotImplementedError) { @client.fetch_server("srv-001") }
    assert_raises(NotImplementedError) { @client.fetch_status("srv-001") }
  end
end
