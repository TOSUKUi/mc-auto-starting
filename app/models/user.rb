class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :owned_minecraft_servers, class_name: "MinecraftServer", foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_exception
  has_many :server_members, dependent: :destroy
  has_many :member_minecraft_servers, through: :server_members, source: :minecraft_server

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :discord_user_id, with: ->(value) { value.present? ? value.to_s.strip : nil }
  normalizes :discord_username, with: ->(value) { value.present? ? value.to_s.strip : nil }
  normalizes :discord_email, with: ->(value) { value.present? ? value.to_s.strip.downcase : nil }

  validates :discord_user_id, uniqueness: true, allow_nil: true

  def self.find_by_discord_auth(auth)
    discord_user_id = auth.dig("uid")
    return if discord_user_id.blank?

    find_by(discord_user_id: discord_user_id)
  end

  def apply_discord_auth!(auth)
    info = auth.fetch("info", {})

    update!(
      discord_user_id: auth.fetch("uid"),
      discord_username: info["name"],
      discord_global_name: info["global_name"],
      discord_avatar: info["image"],
      discord_email: info["email"],
      last_discord_login_at: Time.current,
    )
  end
end
