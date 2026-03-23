class HostnameFormatValidator < ActiveModel::EachValidator
  HOSTNAME_LABEL_PATTERN = /\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/

  def validate_each(record, attribute, value)
    return if value.blank?
    return if value.match?(HOSTNAME_LABEL_PATTERN)

    record.errors.add(attribute, "must use lowercase letters, numbers, and internal hyphens only")
  end
end
