module ExecutionProvider
  class CreateServerRequest
    attr_reader :name,
      :external_id,
      :owner_id,
      :node_id,
      :egg_id,
      :allocation_id,
      :memory_mb,
      :swap_mb,
      :disk_mb,
      :io_weight,
      :cpu_limit,
      :cpu_pinning,
      :oom_killer_enabled,
      :allocation_limit,
      :backup_limit,
      :database_limit,
      :environment,
      :skip_scripts

    def initialize(
      name:,
      external_id: nil,
      owner_id:,
      node_id:,
      egg_id:,
      allocation_id:,
      memory_mb:,
      swap_mb: 0,
      disk_mb:,
      io_weight: 500,
      cpu_limit: 100,
      cpu_pinning: nil,
      oom_killer_enabled: true,
      allocation_limit: 0,
      backup_limit: 0,
      database_limit: 0,
      environment:,
      skip_scripts: false
    )
      @name = name.to_s.strip
      @external_id = external_id.presence
      @owner_id = Integer(owner_id)
      @node_id = Integer(node_id)
      @egg_id = Integer(egg_id)
      @allocation_id = Integer(allocation_id)
      @memory_mb = Integer(memory_mb)
      @swap_mb = Integer(swap_mb)
      @disk_mb = Integer(disk_mb)
      @io_weight = Integer(io_weight)
      @cpu_limit = Integer(cpu_limit)
      @cpu_pinning = cpu_pinning.presence
      @oom_killer_enabled = !!oom_killer_enabled
      @allocation_limit = Integer(allocation_limit)
      @backup_limit = Integer(backup_limit)
      @database_limit = Integer(database_limit)
      @environment = environment.deep_symbolize_keys
      @skip_scripts = !!skip_scripts

      validate!
    end

    def to_provider_payload
      {
        name: name,
        external_id: external_id,
        owner_id: owner_id,
        node_id: node_id,
        egg_id: egg_id,
        allocation: {
          default: allocation_id,
        },
        limits: {
          memory: memory_mb,
          swap: swap_mb,
          disk: disk_mb,
          io: io_weight,
          cpu: cpu_limit,
          threads: cpu_pinning,
          oom_killer: oom_killer_enabled,
        },
        feature_limits: {
          allocations: allocation_limit,
          backups: backup_limit,
          databases: database_limit,
        },
        environment: environment.stringify_keys,
        skip_scripts: skip_scripts,
      }.compact
    end

    private
      def validate!
        raise ValidationError, "name is required" if name.blank?
        raise ValidationError, "environment is required" if environment.blank?

        {
          memory_mb: memory_mb,
          swap_mb: swap_mb,
          disk_mb: disk_mb,
          io_weight: io_weight,
          cpu_limit: cpu_limit,
          allocation_limit: allocation_limit,
          backup_limit: backup_limit,
          database_limit: database_limit,
        }.each do |field_name, value|
          raise ValidationError, "#{field_name} must be greater than or equal to 0" if value.negative?
        end
      end
  end
end
