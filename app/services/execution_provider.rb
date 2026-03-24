module ExecutionProvider
  class << self
    def config
      raw_config = Rails.application.config.x.execution_provider

      return raw_config if raw_config.is_a?(Configuration)

      Configuration.new(
        provider_name: raw_config.provider_name,
        panel_url: raw_config.panel_url,
        application_api_key: raw_config.application_api_key,
        client_api_key: raw_config.client_api_key,
        open_timeout: raw_config.open_timeout,
        read_timeout: raw_config.read_timeout,
        write_timeout: raw_config.write_timeout,
        client_class_name: raw_config.client_class_name,
      )
    end

    def build_client(**overrides)
      resolved_config = config.with_overrides(**overrides)
      client_class = resolved_config.client_class

      client_class.new(configuration: resolved_config)
    end
  end
end
