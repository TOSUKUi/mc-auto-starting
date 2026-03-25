module DockerEngine
  module ManagedLabels
    BASE = {
      "app" => "mc-auto-starting",
      "managed_by" => "rails",
    }.freeze

    module_function

    def base
      BASE.dup
    end

    def for_server(minecraft_server:)
      merge(
        "minecraft_server_id" => minecraft_server.id.to_s,
        "minecraft_server_hostname" => minecraft_server.hostname,
      )
    end

    def merge(labels = {})
      base.merge(normalize_labels(labels))
    end

    def filter(labels = {})
      { "label" => merge(labels).map { |key, value| "#{key}=#{value}" }.sort }
    end

    def normalize_labels(labels)
      labels.to_h.each_with_object({}) do |(key, value), normalized|
        normalized[key.to_s] = value.to_s
      end
    end
  end
end
