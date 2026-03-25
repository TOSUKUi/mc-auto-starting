module Servers
  class LifecycleOperation
    DEFAULT_TIMEOUT_SECONDS = 30

    DOCKER_STATE_TO_RAILS_STATUS = {
      "created" => :stopped,
      "running" => :ready,
      "paused" => :degraded,
      "restarting" => :restarting,
      "removing" => :deleting,
      "exited" => :stopped,
      "dead" => :degraded,
    }.freeze

    def initialize(server:, docker_client: DockerEngine.build_client)
      @server = server
      @docker_client = docker_client
    end

    def call
      return if server.nil?

      perform_docker_operation!
      persist_runtime_after_operation!
      transition_server!
      server
    end

    private
      attr_reader :server, :docker_client

      def container_reference
        server.container_id.presence || server.container_name.presence || raise(
          DockerEngine::ValidationError.new(
            "managed container reference is required for lifecycle operations",
          )
        )
      end

      def perform_docker_operation!
        raise NotImplementedError, "#{self.class.name} must implement #perform_docker_operation!"
      end

      def transition_status
        raise NotImplementedError, "#{self.class.name} must implement #transition_status"
      end

      def persist_runtime_after_operation!
        server.update!(runtime_attributes)
      end

      def runtime_attributes
        inspection = docker_client.inspect_container(id_or_name: container_reference)
        state = inspection.dig("State", "Status").presence || fallback_container_state

        {
          container_id: inspection.fetch("Id", server.container_id),
          container_state: state,
          last_started_at: next_last_started_at,
          last_error_message: nil,
        }
      end

      def fallback_container_state
        mapped_container_state || server.container_state
      end

      def mapped_container_state
        nil
      end

      def next_last_started_at
        server.last_started_at
      end

      def transition_server!
        server.transition_to!(transition_status) if server.can_transition_to?(transition_status)
      end

      def stop_timeout_seconds
        DEFAULT_TIMEOUT_SECONDS
      end

      def restart_timeout_seconds
        DEFAULT_TIMEOUT_SECONDS
      end

      def docker_state_to_rails_status(state)
        DOCKER_STATE_TO_RAILS_STATUS.fetch(state.to_s, :degraded)
      end
  end
end
