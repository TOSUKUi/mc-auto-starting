ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

Rails.application.config.x.execution_provider.provisioning_templates = {
  "fabric" => {
    "owner_id" => 40,
    "node_id" => 2,
    "egg_id" => 9,
    "allocation_id" => 23,
    "environment" => {
      "server_jarfile" => "fabric-server-launch.jar",
    },
  },
  "paper" => {
    "owner_id" => 40,
    "node_id" => 2,
    "egg_id" => 7,
    "allocation_id" => 21,
    "environment" => {
      "server_jarfile" => "paper.jar",
    },
  },
  "velocity" => {
    "owner_id" => 40,
    "node_id" => 2,
    "egg_id" => 8,
    "allocation_id" => 22,
    "environment" => {
      "server_jarfile" => "velocity.jar",
    },
  },
}

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
