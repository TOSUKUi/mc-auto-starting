class ReservedHostnameValidator < ActiveModel::EachValidator
  RESERVED_HOSTNAMES = %w[
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

  def validate_each(record, attribute, value)
    return if value.blank?
    return unless RESERVED_HOSTNAMES.include?(value)

    record.errors.add(attribute, "is reserved")
  end
end
