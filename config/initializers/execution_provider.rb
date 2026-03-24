Rails.application.config.x.execution_provider.provider_name = ENV.fetch("EXECUTION_PROVIDER_NAME", "pterodactyl")
Rails.application.config.x.execution_provider.panel_url = ENV["EXECUTION_PROVIDER_PANEL_URL"]
Rails.application.config.x.execution_provider.application_api_key = ENV["EXECUTION_PROVIDER_APPLICATION_API_KEY"]
Rails.application.config.x.execution_provider.client_api_key = ENV["EXECUTION_PROVIDER_CLIENT_API_KEY"]
Rails.application.config.x.execution_provider.open_timeout = ENV.fetch("EXECUTION_PROVIDER_OPEN_TIMEOUT", 5)
Rails.application.config.x.execution_provider.read_timeout = ENV.fetch("EXECUTION_PROVIDER_READ_TIMEOUT", 30)
Rails.application.config.x.execution_provider.write_timeout = ENV.fetch("EXECUTION_PROVIDER_WRITE_TIMEOUT", 30)
Rails.application.config.x.execution_provider.client_class_name = ENV["EXECUTION_PROVIDER_CLIENT_CLASS"]
