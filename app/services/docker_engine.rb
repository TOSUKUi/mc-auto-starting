module DockerEngine
  Response = Data.define(:status, :headers, :body)

  class Error < StandardError; end
  class ConnectionError < Error; end
  class TimeoutError < Error; end
  class ConfigurationError < Error; end

  class RequestError < Error
    attr_reader :status, :body

    def initialize(message, status: nil, body: nil)
      super(message)
      @status = status
      @body = body
    end
  end

  class NotFoundError < RequestError; end
  class ConflictError < RequestError; end
  class ValidationError < RequestError; end

  class << self
    def config
      raw_config = Rails.application.config.x.docker_engine

      return raw_config if raw_config.is_a?(Configuration)

      Configuration.new(
        socket_path: raw_config.socket_path,
        api_version: raw_config.api_version,
        open_timeout: raw_config.open_timeout,
        read_timeout: raw_config.read_timeout,
        write_timeout: raw_config.write_timeout,
      )
    end

    def build_client(**overrides)
      resolved_config = config.with_overrides(**overrides)
      Client.new(configuration: resolved_config)
    end
  end
end
