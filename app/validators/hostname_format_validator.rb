class HostnameFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    return if MinecraftServerHostname.valid_format?(value)

    record.errors.add(attribute, "must use lowercase letters, numbers, and internal hyphens only")
  end
end
