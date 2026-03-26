module Router
  class Configuration
    RELOAD_STRATEGIES = %w[watch command docker_signal manual].freeze

    attr_reader :routes_config_path, :reload_strategy, :reload_command, :reload_signal, :reload_container_labels, :api_url

    def initialize(routes_config_path:, reload_strategy: "watch", reload_command: nil, reload_signal: "HUP", reload_container_labels: nil, api_url: nil)
      @routes_config_path = routes_config_path.to_s.strip
      @reload_strategy = reload_strategy.to_s
      @reload_command = reload_command.to_s.strip.presence
      @reload_signal = reload_signal.to_s.strip.presence || "HUP"
      @reload_container_labels = Array(reload_container_labels).map { |value| value.to_s.strip }.reject(&:blank?).uniq.sort
      @api_url = api_url.to_s.strip.presence

      validate!
    end

    def watch?
      reload_strategy == "watch"
    end

    def command?
      reload_strategy == "command"
    end

    def docker_signal?
      reload_strategy == "docker_signal"
    end

    def manual?
      reload_strategy == "manual"
    end

    def with_overrides(**overrides)
      self.class.new(**to_h.merge(overrides))
    end

    def to_h
      {
        routes_config_path: routes_config_path,
        reload_strategy: reload_strategy,
        reload_command: reload_command,
        reload_signal: reload_signal,
        reload_container_labels: reload_container_labels,
        api_url: api_url,
      }
    end

    private
      def validate!
        raise ConfigurationError, "mc_router routes_config_path is required" if routes_config_path.blank?
        raise ConfigurationError, "mc_router reload_strategy must be one of: #{RELOAD_STRATEGIES.join(', ')}" unless RELOAD_STRATEGIES.include?(reload_strategy)
        raise ConfigurationError, "mc_router reload_command is required when reload_strategy=command" if command? && reload_command.blank?
        raise ConfigurationError, "mc_router reload_container_labels is required when reload_strategy=docker_signal" if docker_signal? && reload_container_labels.empty?
      end
  end
end
