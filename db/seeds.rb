def bootstrap_discord_owner
  discord_user_id = ENV["BOOTSTRAP_DISCORD_USER_ID"].to_s.strip
  return if discord_user_id.blank?

  email_address = ENV["BOOTSTRAP_EMAIL_ADDRESS"].presence || "bootstrap-owner-#{discord_user_id}@example.invalid"
  discord_username = ENV["BOOTSTRAP_DISCORD_USERNAME"].presence || "bootstrap-owner"
  password = ENV["BOOTSTRAP_PASSWORD"].presence || SecureRandom.base58(24)

  user = User.find_or_initialize_by(discord_user_id: discord_user_id)
  user.email_address = email_address
  user.discord_username = discord_username

  if user.new_record?
    user.password = password
    user.password_confirmation = password
  end

  user.save!
end

def seed_development_user
  development_user = User.find_or_initialize_by(email_address: "dev@example.com")
  development_user.password = "password"
  development_user.password_confirmation = "password"
  development_user.save!
end

bootstrap_discord_owner
seed_development_user if Rails.env.development?
