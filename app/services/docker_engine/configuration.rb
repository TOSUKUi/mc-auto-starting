module DockerEngine
  class Configuration
    attr_reader :socket_path, :api_version, :open_timeout, :read_timeout, :write_timeout

    def initialize(socket_path:, api_version: nil, open_timeout: 5, read_timeout: 30, write_timeout: 30)
      @socket_path = socket_path.to_s
      @api_version = api_version.to_s.delete_prefix("/").presence
      @open_timeout = Integer(open_timeout)
      @read_timeout = Integer(read_timeout)
      @write_timeout = Integer(write_timeout)
    end

    def with_overrides(**overrides)
      self.class.new(**to_h.merge(overrides))
    end

    def to_h
      {
        socket_path: socket_path,
        api_version: api_version,
        open_timeout: open_timeout,
        read_timeout: read_timeout,
        write_timeout: write_timeout,
      }
    end
  end
end
