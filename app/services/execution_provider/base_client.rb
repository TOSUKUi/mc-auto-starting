module ExecutionProvider
  class BaseClient
    attr_reader :configuration

    def initialize(configuration:)
      @configuration = configuration
    end

    def create_server(_request)
      raise NotImplementedError, "#{self.class.name} must implement #create_server"
    end

    def delete_server(_provider_server_id)
      raise NotImplementedError, "#{self.class.name} must implement #delete_server"
    end

    def start_server(_provider_server_id)
      raise NotImplementedError, "#{self.class.name} must implement #start_server"
    end

    def stop_server(_provider_server_id)
      raise NotImplementedError, "#{self.class.name} must implement #stop_server"
    end

    def restart_server(_provider_server_id)
      raise NotImplementedError, "#{self.class.name} must implement #restart_server"
    end

    def fetch_server(_provider_server_id)
      raise NotImplementedError, "#{self.class.name} must implement #fetch_server"
    end

    def fetch_status(_provider_server_id)
      raise NotImplementedError, "#{self.class.name} must implement #fetch_status"
    end
  end
end
