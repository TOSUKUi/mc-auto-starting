module Servers
  class SyncServerState
    def initialize(server:, docker_client: DockerEngine.build_client)
      @server = server
      @docker_client = docker_client
    end

    def call
      return if server.nil?

      inspection = docker_client.inspect_container(id_or_name: container_reference)
      apply_runtime_state!(inspection)
      server
    rescue DockerEngine::NotFoundError => error
      mark_missing_runtime!(error)
      server
    end

    private
      DOCKER_STATE_TO_RAILS_STATUS = Servers::LifecycleOperation::DOCKER_STATE_TO_RAILS_STATUS

      attr_reader :server, :docker_client

      def container_reference
        server.container_id.presence || server.container_name.presence || raise(
          DockerEngine::ValidationError.new(
            "managed container reference is required for lifecycle operations",
          )
        )
      end

      def apply_runtime_state!(inspection)
        container_state = inspection.dig("State", "Status").presence || "unknown"
        mapped_status = DOCKER_STATE_TO_RAILS_STATUS.fetch(container_state, :degraded)

        server.update!(
          container_id: inspection.fetch("Id", server.container_id),
          container_state: container_state,
          last_error_message: nil,
        )

        apply_status!(mapped_status)
      end

      def apply_status!(next_status)
        next_status = next_status.to_sym
        return if server.status.to_sym == next_status

        if server.can_transition_to?(next_status)
          server.transition_to!(next_status)
        else
          transition_to_degraded!
        end
      end

      def mark_missing_runtime!(error)
        server.update!(
          container_id: nil,
          container_state: nil,
          last_error_message: error.message,
        )
        transition_to_degraded!
      end

      def transition_to_degraded!
        server.transition_to!(:degraded) if server.can_transition_to?(:degraded)
      end
  end
end
