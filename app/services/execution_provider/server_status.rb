module ExecutionProvider
  ServerStatus = Data.define(
    :provider_server_id,
    :state,
    :rails_status,
    :raw
  )
end
