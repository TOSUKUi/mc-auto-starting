module MinecraftServerHostname
  LABEL_PATTERN = /\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/
  RESERVED = %w[
    admin
    api
    app
    health
    internal
    mc-router
    root
    status
    support
    system
    www
  ].freeze

  module_function

  def normalize(value)
    value.to_s.strip.downcase
  end

  def valid_format?(value)
    value.present? && value.match?(LABEL_PATTERN)
  end

  def reserved?(value)
    RESERVED.include?(normalize(value))
  end

  def container_name_for(value)
    normalized = normalize(value)
    return if normalized.blank?

    "mc-server-#{normalized}"
  end

  def volume_name_for(value)
    normalized = normalize(value)
    return if normalized.blank?

    "mc-data-#{normalized}"
  end
end
