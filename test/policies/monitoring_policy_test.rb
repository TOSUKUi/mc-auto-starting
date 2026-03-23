require "test_helper"

class MonitoringPolicyTest < ActiveSupport::TestCase
  test "monitoring access is denied by default" do
    policy = MonitoringPolicy.new(users(:one), :monitoring)

    assert_not policy.index?
    assert_not policy.show?
  end
end
