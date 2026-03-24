module ExecutionProvider
  class Configuration
    attr_reader :provider_name,
      :panel_url,
      :application_api_key,
      :client_api_key,
      :open_timeout,
      :read_timeout,
      :write_timeout,
      :client_class_name,
      :provisioning_templates

    def initialize(
      provider_name:,
      panel_url: nil,
      application_api_key: nil,
      client_api_key: nil,
      open_timeout: 5,
      read_timeout: 30,
      write_timeout: 30,
      client_class_name: nil,
      provisioning_templates: {}
    )
      @provider_name = provider_name.to_s
      @panel_url = panel_url.presence
      @application_api_key = application_api_key.presence
      @client_api_key = client_api_key.presence
      @open_timeout = Integer(open_timeout)
      @read_timeout = Integer(read_timeout)
      @write_timeout = Integer(write_timeout)
      @client_class_name = (client_class_name.presence || default_client_class_name_for(@provider_name))
      @provisioning_templates = provisioning_templates.deep_symbolize_keys
    end

    def client_class
      client_class_name.constantize
    rescue NameError => error
      raise UnsupportedProviderError, "execution provider client class is not available: #{client_class_name} (provider: #{provider_name})", cause: error
    end

    def with_overrides(**overrides)
      self.class.new(**to_h.merge(overrides))
    end

    def to_h
      {
        provider_name: provider_name,
        panel_url: panel_url,
        application_api_key: application_api_key,
        client_api_key: client_api_key,
        open_timeout: open_timeout,
        read_timeout: read_timeout,
        write_timeout: write_timeout,
        client_class_name: client_class_name,
        provisioning_templates: provisioning_templates,
      }
    end

    private
      def default_client_class_name_for(name)
        case name
        when "pterodactyl"
          "ExecutionProvider::PterodactylClient"
        else
          raise UnsupportedProviderError, "unsupported execution provider: #{name}"
        end
      end
  end
end
