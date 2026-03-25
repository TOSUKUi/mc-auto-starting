class ReservedHostnameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    return unless MinecraftServerHostname.reserved?(value)

    record.errors.add(attribute, "is reserved")
  end
end
