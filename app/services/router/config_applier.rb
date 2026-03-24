require "fileutils"
require "open3"
require "shellwords"
require "tempfile"

module Router
  class ConfigApplier
    ApplyResult = Data.define(:path, :reload_strategy, :reloaded)

    def initialize(configuration: Router.config)
      @configuration = configuration
    end

    def call(routes:)
      rendered_config = ConfigRenderer.new(routes: routes).call

      write_config(rendered_config)
      reloaded = trigger_reload

      ApplyResult.new(
        path: configuration.routes_config_path,
        reload_strategy: configuration.reload_strategy,
        reloaded: reloaded,
      )
    end

    private
      attr_reader :configuration

      def write_config(rendered_config)
        path = Pathname.new(configuration.routes_config_path)
        FileUtils.mkdir_p(path.dirname)

        Tempfile.create([ path.basename.to_s, ".tmp" ], path.dirname.to_s) do |file|
          file.write(rendered_config)
          file.flush
          file.fsync
          file.close

          FileUtils.mv(file.path, path.to_s)
        end
      end

      def trigger_reload
        return true if configuration.watch?
        return false if configuration.manual?

        stdout, stderr, status = Open3.capture3(*Shellwords.split(configuration.reload_command))
        return true if status.success?

        raise ApplyError, "mc_router reload command failed: #{stderr.presence || stdout.presence || 'unknown error'}"
      end
  end
end
