require "test_helper"
require "stringio"

class BootstrapOwnerLoginHintTest < ActiveSupport::TestCase
  test "uses app base url when configured" do
    with_env(
      "APP_BASE_URL" => "https://panel.example.test/",
      "BOOTSTRAP_DISCORD_USER_ID" => "123456789012345678",
      "DISCORD_CLIENT_ID" => "client-id",
      "DISCORD_CLIENT_SECRET" => "client-secret",
    ) do
      assert_equal "https://panel.example.test/login", BootstrapOwnerLoginHint.login_url
    end
  end

  test "defaults to localhost in development without app base url" do
    with_env("APP_BASE_URL" => nil) do
      with_singleton_override(BootstrapOwnerLoginHint, :default_base_url, "http://localhost:3000") do
        assert_equal "http://localhost:3000/login", BootstrapOwnerLoginHint.login_url
      end
    end
  end

  test "logs bootstrap hint when configuration is complete" do
    output = StringIO.new
    logger = Logger.new(output)

    with_env(
      "APP_BASE_URL" => "https://panel.example.test",
      "BOOTSTRAP_DISCORD_USER_ID" => "123456789012345678",
      "DISCORD_CLIENT_ID" => "client-id",
      "DISCORD_CLIENT_SECRET" => "client-secret",
    ) do
      with_singleton_override(BootstrapOwnerLoginHint, :server_process?, true) do
        BootstrapOwnerLoginHint.log!(logger: logger)
      end
    end

    assert_includes output.string, "Bootstrap Discord owner login: https://panel.example.test/login"
    assert_includes output.string, "/discord-invitations"
  end

  test "does not log bootstrap hint without oauth configuration" do
    output = StringIO.new
    logger = Logger.new(output)

    with_env(
      "APP_BASE_URL" => "https://panel.example.test",
      "BOOTSTRAP_DISCORD_USER_ID" => "123456789012345678",
      "DISCORD_CLIENT_ID" => nil,
      "DISCORD_CLIENT_SECRET" => nil,
    ) do
      with_singleton_override(BootstrapOwnerLoginHint, :server_process?, true) do
        BootstrapOwnerLoginHint.log!(logger: logger)
      end
    end

    assert_empty output.string
  end

  private
    def with_singleton_override(target, method_name, value)
      singleton = target.singleton_class
      original_defined = singleton.method_defined?(method_name) || singleton.private_method_defined?(method_name)
      original_method = singleton.instance_method(method_name) if original_defined

      singleton.define_method(method_name) { value }
      yield
    ensure
      singleton.send(:remove_method, method_name)
      singleton.define_method(method_name, original_method) if original_defined
    end

    def with_env(overrides)
      original = overrides.to_h { |key, _value| [ key, ENV[key] ] }

      overrides.each do |key, value|
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end

      yield
    ensure
      original.each do |key, value|
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end
    end
end
