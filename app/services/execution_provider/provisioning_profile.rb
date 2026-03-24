module ExecutionProvider
  ProvisioningProfile = Data.define(
    :owner_id,
    :node_id,
    :egg_id,
    :allocation_id,
    :environment,
    :skip_scripts,
    :swap_mb,
    :io_weight,
    :cpu_limit,
    :cpu_pinning,
    :oom_killer_enabled,
    :allocation_limit,
    :backup_limit,
    :database_limit
  )
end
