require "json"
require "net/http"
require "uri"

module MinecraftRuntime
  class VersionCatalog
    def initialize(cache: Rails.cache, logger: Rails.logger, http_client: HttpClient.new, cache_ttl: MinecraftRuntime.version_options_cache_ttl)
      @cache = cache
      @logger = logger
      @http_client = http_client
      @cache_ttl = cache_ttl
    end

    def version_options(runtime_family:)
      normalized_runtime_family = MinecraftRuntime.normalize_runtime_family(runtime_family)

      cache.fetch(cache_key(normalized_runtime_family), expires_in: cache_ttl) do
        build_live_options(runtime_family: normalized_runtime_family)
      end
    rescue StandardError => error
      logger.warn("MinecraftRuntime::VersionCatalog fallback for #{normalized_runtime_family}: #{error.class}: #{error.message}")
      MinecraftRuntime.fallback_version_options(runtime_family: normalized_runtime_family)
    end

    def version_options_by_runtime_family
      MinecraftRuntime.catalog.keys.to_h do |runtime_family|
        [ runtime_family, version_options(runtime_family: runtime_family) ]
      end
    end

    private
      attr_reader :cache, :logger, :http_client, :cache_ttl

      def build_live_options(runtime_family:)
        payload = http_client.get_json(MinecraftRuntime.version_source_url(runtime_family: runtime_family))
        options = case runtime_family
        when "vanilla"
          build_vanilla_options(payload)
        when "paper"
          build_paper_options(payload)
        else
          []
        end

        return MinecraftRuntime.fallback_version_options(runtime_family: runtime_family) if options.empty?

        options
      end

      def build_vanilla_options(payload)
        latest_release = payload.dig("latest", "release").to_s
        releases = Array(payload["versions"])
          .select { |version| version["type"] == "release" }
          .map { |version| version["id"].to_s }

        build_options(versions: releases, latest_version: latest_release)
      end

      def build_paper_options(payload)
        latest_release = payload["latest"].to_s
        releases = payload.fetch("versions", {}).keys.select do |version|
          version.to_s.match?(MinecraftRuntime::STABLE_VERSION_PATTERN)
        end

        build_options(versions: releases, latest_version: latest_release)
      end

      def build_options(versions:, latest_version:)
        normalized_versions = versions.filter_map(&:presence).uniq
        options = []
        options << latest_option(latest_version) if latest_version.present?
        options.concat(normalized_versions.map { |version| { value: version, label: version } })
        options.uniq
      end

      def latest_option(latest_version)
        {
          value: MinecraftRuntime.default_version_tag,
          label: "#{latest_version} (latest)",
        }
      end

      def cache_key(runtime_family)
        "minecraft_runtime/version_options/#{runtime_family}"
      end

      class HttpClient
        def get_json(url)
          uri = URI.parse(url)
          response = Net::HTTP.get_response(uri)
          raise ArgumentError, "unexpected response status #{response.code} for #{url}" unless response.is_a?(Net::HTTPSuccess)

          JSON.parse(response.body)
        end
      end
  end
end
