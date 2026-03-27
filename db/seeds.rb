def bootstrap_discord_owner
  discord_user_id = ENV["BOOTSTRAP_DISCORD_USER_ID"].to_s.strip
  return if discord_user_id.blank?

  discord_username = ENV["BOOTSTRAP_DISCORD_USERNAME"].presence || "bootstrap-owner"
  password = SecureRandom.base58(24)

  user = User.find_or_initialize_by(discord_user_id: discord_user_id)
  user.discord_username = discord_username

  if user.new_record?
    user.password = password
    user.password_confirmation = password
  end

  user.save!
end

bootstrap_discord_owner
