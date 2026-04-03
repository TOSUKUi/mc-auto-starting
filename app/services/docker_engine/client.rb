require "cgi"
require "json"

module DockerEngine
  class Client
    def initialize(configuration: DockerEngine.config, connection: nil)
      @configuration = configuration
      @connection = connection || Connection.new(configuration: configuration)
    end

    def ping!
      connection.request(method: :get, path: "/_ping", versioned: false).body == "OK"
    end

    def version
      connection.request(method: :get, path: "/version", versioned: false).body
    end

    def inspect_container(id_or_name:)
      connection.request(method: :get, path: "/containers/#{escape_path(id_or_name)}/json").body
    end

    def inspect_volume(name:)
      connection.request(method: :get, path: "/volumes/#{escape_path(name)}").body
    end

    def list_containers(filters: {}, all: true)
      connection.request(
        method: :get,
        path: "/containers/json",
        query: {
          all: all ? 1 : 0,
          filters: JSON.generate(normalize_filters(filters)),
        },
      ).body
    end

    def list_managed_containers(filters: {})
      merged_filters = normalize_filters(filters)
      managed_labels = Array(merged_filters["label"]) + ManagedLabels.filter.fetch("label")
      merged_filters["label"] = managed_labels.uniq.sort

      connection.request(
        method: :get,
        path: "/containers/json",
        query: {
          all: 1,
          filters: JSON.generate(merged_filters),
        },
      ).body
    end

    def create_volume(name:, labels: {})
      connection.request(
        method: :post,
        path: "/volumes/create",
        body: {
          Name: name,
          Labels: ManagedLabels.merge(labels),
        },
      ).body
    end

    def pull_image(image:)
      connection.request(
        method: :post,
        path: "/images/create",
        query: { fromImage: image },
        body: nil,
      ).status == 200
    end

    def remove_volume(name:)
      connection.request(method: :delete, path: "/volumes/#{escape_path(name)}").status == 204
    end

    def create_container(name:, image:, env:, mounts:, labels:, network_name:, memory_mb:)
      connection.request(
        method: :post,
        path: "/containers/create",
        query: { name: name },
        body: container_payload(
          image: image,
          env: env,
          mounts: mounts,
          labels: labels,
          network_name: network_name,
          memory_mb: memory_mb,
        ),
      ).body
    end

    def signal_container(id:, signal:)
      connection.request(
        method: :post,
        path: "/containers/#{escape_path(id)}/kill",
        query: { signal: signal.to_s },
      ).status == 204
    end

    def start_container(id:)
      connection.request(method: :post, path: "/containers/#{escape_path(id)}/start").status == 204
    end

    def stop_container(id:, timeout_seconds:)
      connection.request(
        method: :post,
        path: "/containers/#{escape_path(id)}/stop",
        query: { t: Integer(timeout_seconds) },
      ).status == 204
    end

    def restart_container(id:, timeout_seconds:)
      connection.request(
        method: :post,
        path: "/containers/#{escape_path(id)}/restart",
        query: { t: Integer(timeout_seconds) },
      ).status == 204
    end

    def container_logs(id:, tail:, stdout: true, stderr: true, timestamps: false)
      connection.request(
        method: :get,
        path: "/containers/#{escape_path(id)}/logs",
        query: {
          stdout: stdout ? 1 : 0,
          stderr: stderr ? 1 : 0,
          timestamps: timestamps ? 1 : 0,
          tail: Integer(tail),
        },
      ).body.to_s
    end

    def remove_container(id:, force: false)
      connection.request(
        method: :delete,
        path: "/containers/#{escape_path(id)}",
        query: { force: force ? 1 : 0 },
      ).status == 204
    end

    private
      attr_reader :configuration, :connection

      def container_payload(image:, env:, mounts:, labels:, network_name:, memory_mb:)
        payload = {
          Image: image,
          Env: normalize_env(env),
          Labels: ManagedLabels.merge(labels),
          HostConfig: {
            Mounts: mounts,
            Memory: Integer(memory_mb) * 1024 * 1024,
            RestartPolicy: {
              Name: "unless-stopped",
            },
          },
        }

        payload[:NetworkingConfig] = {
          EndpointsConfig: {
            network_name => {},
          },
        } if network_name.present?

        payload
      end

      def normalize_env(env)
        env.to_h.map { |key, value| "#{key}=#{value}" }.sort
      end

      def normalize_filters(filters)
        filters.to_h.each_with_object({}) do |(key, value), normalized|
          normalized[key.to_s] = value
        end
      end

      def escape_path(value)
        CGI.escape(value.to_s)
      end
  end
end
