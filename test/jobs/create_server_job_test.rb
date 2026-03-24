require "test_helper"

class CreateServerJobTest < ActiveJob::TestCase
  test "delegates provisioning to the server provisioning service" do
    server = minecraft_servers(:two)
    called = []
    fake_service = Object.new
    fake_service.define_singleton_method(:call) { called << :called }
    original_new = Servers::ProvisionServer.method(:new)

    Servers::ProvisionServer.define_singleton_method(:new) do |*|
      fake_service
    end

    begin
      CreateServerJob.perform_now(server.id)
    ensure
      Servers::ProvisionServer.define_singleton_method(:new, original_new)
    end

    assert_equal [ :called ], called
  end

  test "returns when the server record no longer exists" do
    assert_nil CreateServerJob.perform_now(-1)
  end
end
