module ExecutionProvider
  class ProvisioningProfileResolver
    def initialize(server:, configuration: ExecutionProvider.config)
      @server = server
      @configuration = configuration
    end

    def call
      template_config = configuration.provisioning_templates.fetch(server.template_kind.to_sym) do
        raise ValidationError, "execution provider provisioning template is not configured: #{server.template_kind}"
      end

      ProvisioningProfile.new(
        owner_id: Integer(fetch_required(template_config, :owner_id)),
        node_id: Integer(fetch_required(template_config, :node_id)),
        egg_id: Integer(fetch_required(template_config, :egg_id)),
        allocation_id: Integer(fetch_required(template_config, :allocation_id)),
        environment: resolved_environment(template_config),
        skip_scripts: ActiveModel::Type::Boolean.new.cast(template_config.fetch(:skip_scripts, false)),
        swap_mb: Integer(template_config.fetch(:swap_mb, 0)),
        io_weight: Integer(template_config.fetch(:io_weight, 500)),
        cpu_limit: Integer(template_config.fetch(:cpu_limit, 100)),
        cpu_pinning: template_config[:cpu_pinning].presence,
        oom_killer_enabled: ActiveModel::Type::Boolean.new.cast(template_config.fetch(:oom_killer_enabled, true)),
        allocation_limit: Integer(template_config.fetch(:allocation_limit, 0)),
        backup_limit: Integer(template_config.fetch(:backup_limit, 0)),
        database_limit: Integer(template_config.fetch(:database_limit, 0)),
      )
    end

    private
      attr_reader :server, :configuration

      def resolved_environment(template_config)
        environment = template_config.fetch(:environment, {}).deep_symbolize_keys

        environment.reverse_merge(
          minecraft_version: server.minecraft_version,
        )
      end

      def fetch_required(hash, key)
        value = hash[key]
        return value if value.present?

        raise ValidationError, "execution provider provisioning template #{server.template_kind} is missing #{key}"
      end
  end
end
