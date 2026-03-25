require "test_helper"

class DockerEngine::ManagedLabelsTest < ActiveSupport::TestCase
  test "builds base labels for managed resources" do
    assert_equal(
      {
        "app" => "mc-auto-starting",
        "managed_by" => "rails",
      },
      DockerEngine::ManagedLabels.base,
    )
  end

  test "builds server-specific managed labels" do
    labels = DockerEngine::ManagedLabels.for_server(minecraft_server: minecraft_servers(:one))

    assert_equal "mc-auto-starting", labels.fetch("app")
    assert_equal "rails", labels.fetch("managed_by")
    assert_equal minecraft_servers(:one).id.to_s, labels.fetch("minecraft_server_id")
    assert_equal "main-survival", labels.fetch("minecraft_server_hostname")
  end

  test "builds docker label filters for managed resources" do
    assert_equal(
      {
        "label" => [
          "app=mc-auto-starting",
          "managed_by=rails",
          "minecraft_server_hostname=main-survival",
        ],
      },
      DockerEngine::ManagedLabels.filter("minecraft_server_hostname" => "main-survival"),
    )
  end
end
