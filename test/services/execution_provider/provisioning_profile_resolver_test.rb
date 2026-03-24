require "test_helper"

class ExecutionProvider::ProvisioningProfileResolverTest < ActiveSupport::TestCase
  test "resolves template provisioning settings and merges minecraft version" do
    configuration = ExecutionProvider::Configuration.new(
      provider_name: "pterodactyl",
      provisioning_templates: {
        paper: {
          owner_id: 50,
          node_id: 2,
          egg_id: 7,
          allocation_id: 11,
          environment: {
            server_jarfile: "paper.jar",
          },
          skip_scripts: true,
          cpu_limit: 150,
        },
      },
    )

    profile = ExecutionProvider::ProvisioningProfileResolver.new(
      server: minecraft_servers(:one),
      configuration: configuration,
    ).call

    assert_equal 50, profile.owner_id
    assert_equal 2, profile.node_id
    assert_equal 7, profile.egg_id
    assert_equal 11, profile.allocation_id
    assert_equal true, profile.skip_scripts
    assert_equal 150, profile.cpu_limit
    assert_equal "1.21.4", profile.environment[:minecraft_version]
    assert_equal "paper.jar", profile.environment[:server_jarfile]
  end

  test "rejects missing template config" do
    error = assert_raises(ExecutionProvider::ValidationError) do
      ExecutionProvider::ProvisioningProfileResolver.new(
        server: minecraft_servers(:one),
        configuration: ExecutionProvider::Configuration.new(provider_name: "pterodactyl"),
      ).call
    end

    assert_equal "execution provider provisioning template is not configured: paper", error.message
  end
end
