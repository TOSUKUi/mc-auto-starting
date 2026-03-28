require "rcon"
require "openssl"
require "timeout"

module MinecraftRcon
  DEFAULT_PORT = 25_575
  DEFAULT_CONNECT_TIMEOUT = 5.0
  DEFAULT_COMMAND_TIMEOUT = 5.0
  DEFAULT_SEGMENTED_RESPONSE_WAIT = 0.15
  PASSWORD_LENGTH = 32

  class Error < StandardError; end
  class UnavailableError < Error; end
  class AuthenticationError < Error; end
  class CommandError < Error; end

  module_function

  def port
    config.port.presence || DEFAULT_PORT
  end

  def connect_timeout
    config.connect_timeout.presence || DEFAULT_CONNECT_TIMEOUT
  end

  def command_timeout
    config.command_timeout.presence || DEFAULT_COMMAND_TIMEOUT
  end

  def segmented_response_wait
    config.segmented_response_wait.presence || DEFAULT_SEGMENTED_RESPONSE_WAIT
  end

  def host_for(server)
    server.container_name
  end

  def password_for(server)
    raise UnavailableError, "RCON password requires a persisted server" if server.id.blank?

    secret = config.password_secret.presence || Rails.application.secret_key_base
    raise UnavailableError, "RCON password secret is not configured" if secret.blank?

    OpenSSL::HMAC.hexdigest("SHA256", secret, "#{server.id}:#{server.hostname}")[0, PASSWORD_LENGTH]
  end

  def connection_for(server, client_class: ::Rcon::Client)
    Connection.new(server: server, client_class: client_class)
  end

  def config
    Rails.application.config.x.minecraft_rcon
  end

  class Connection
    def initialize(server:, client_class: ::Rcon::Client)
      @server = server
      @client_class = client_class
    end

    def execute(command, segmented: false)
      validate_server!

      Timeout.timeout(MinecraftRcon.connect_timeout + MinecraftRcon.command_timeout) do
        client = build_client
        authenticate!(client)

        if segmented
          client.execute(command, expect_segmented_response: true, wait: MinecraftRcon.segmented_response_wait)
        else
          client.execute(command)
        end
      end
    rescue Timeout::Error => error
      raise UnavailableError, "RCON command timed out: #{command}"
    rescue StandardError => error
      raise map_error(error, command: command)
    end

    private
      attr_reader :server, :client_class

      def validate_server!
        raise UnavailableError, "server must be persisted before using RCON" if server.id.blank?
        raise UnavailableError, "server container is not ready for RCON" if server.container_name.blank?
      end

      def build_client
        client_class.new(
          host: MinecraftRcon.host_for(server),
          port: MinecraftRcon.port,
          password: MinecraftRcon.password_for(server),
        )
      rescue ArgumentError
        client_class.new(MinecraftRcon.host_for(server), MinecraftRcon.port, MinecraftRcon.password_for(server))
      end

      def authenticate!(client)
        client.authenticate!(ignore_first_packet: false)
      end

      def map_error(error, command:)
        case error.class.name
        when /Authentication/i
          AuthenticationError.new("RCON authentication failed for #{server.hostname}")
        when /ConnectionRefused/i, /SocketError/i, /ECONN/i
          UnavailableError.new("RCON connection failed for #{server.hostname}")
        when /Error$/i
          CommandError.new("RCON command failed: #{command}: #{error.message}")
        else
          Error.new("RCON command failed: #{command}: #{error.message}")
        end
      end
  end
end
