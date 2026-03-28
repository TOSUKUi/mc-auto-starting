require "test_helper"
require "tmpdir"

class Router::RepairPublicationTest < ActiveSupport::TestCase
  test "reapplies the desired route and clears the last error on success" do
    server = minecraft_servers(:one)
    server.update!(last_error_message: "old route failure")

    Dir.mktmpdir do |dir|
      path = File.join(dir, "routes.json")
      File.write(path, { "default-server" => nil, "mappings" => {} }.to_json)
      configuration = Router::Configuration.new(routes_config_path: path, reload_strategy: "manual")
      applier = Router::ConfigApplier.new(configuration: configuration)
      audit = Router::PublicationAudit.new(configuration: configuration)

      Router::RepairPublication.new(server: server, applier: applier, audit: audit).call

      server.reload
      assert_equal "success", server.router_route.last_apply_status
      assert_nil server.last_error_message
    end
  end
end
