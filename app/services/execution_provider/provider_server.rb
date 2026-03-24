module ExecutionProvider
  ProviderServer = Data.define(
    :provider_server_id,
    :identifier,
    :name,
    :backend_host,
    :backend_port,
    :node_id,
    :allocation_id,
    :raw
  )
end
