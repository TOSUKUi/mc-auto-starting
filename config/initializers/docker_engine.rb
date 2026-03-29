Rails.application.config.x.docker_engine.socket_path = "/var/run/docker.sock"
Rails.application.config.x.docker_engine.api_version = ENV["DOCKER_ENGINE_API_VERSION"].presence
Rails.application.config.x.docker_engine.open_timeout = 5
Rails.application.config.x.docker_engine.read_timeout = 30
Rails.application.config.x.docker_engine.write_timeout = 30
