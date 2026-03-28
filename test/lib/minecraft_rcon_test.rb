require "test_helper"

class MinecraftRconTest < ActiveSupport::TestCase
  AuthenticationFailure = Class.new(StandardError)

  test "password generation is stable per server" do
    server = minecraft_servers(:one)

    assert_equal MinecraftRcon.password_for(server), MinecraftRcon.password_for(server)
  end

  test "password generation differs between servers" do
    assert_not_equal MinecraftRcon.password_for(minecraft_servers(:one)), MinecraftRcon.password_for(minecraft_servers(:two))
  end

  test "connection maps authentication errors" do
    server = minecraft_servers(:one)
    fake_client = Class.new do
      def initialize(*); end

      def authenticate!(**)
        raise MinecraftRconTest::AuthenticationFailure, "bad auth"
      end
    end

    error = assert_raises(MinecraftRcon::AuthenticationError) do
      MinecraftRcon.connection_for(server, client_class: fake_client).execute("whitelist list")
    end

    assert_match(/authentication failed/i, error.message)
  end

  test "runtime env enables RCON with the derived password" do
    server = minecraft_servers(:one)
    env = MinecraftRuntime.container_env(server: server)

    assert_equal "TRUE", env.fetch("ENABLE_RCON")
    assert_equal MinecraftRcon.port.to_s, env.fetch("RCON_PORT")
    assert_equal MinecraftRcon.password_for(server), env.fetch("RCON_PASSWORD")
  end
end
