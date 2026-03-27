class User < ApplicationRecord
  USER_TYPES = {
    admin: "admin",
    operator: "operator",
    reader: "reader",
  }.freeze
  OPERATOR_CREATE_MEMORY_QUOTA_MB = 5120

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :owned_minecraft_servers, class_name: "MinecraftServer", foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_exception
  has_many :server_members, dependent: :destroy
  has_many :member_minecraft_servers, through: :server_members, source: :minecraft_server
  has_many :issued_discord_invitations, class_name: "DiscordInvitation", foreign_key: :invited_by_id, inverse_of: :invited_by, dependent: :restrict_with_exception

  enum :user_type, USER_TYPES, validate: true

  normalizes :discord_user_id, with: ->(value) { value.present? ? value.to_s.strip : nil }
  normalizes :discord_username, with: ->(value) { value.present? ? value.to_s.strip : nil }

  validates :discord_user_id, uniqueness: true, allow_nil: true
  validates :user_type, presence: true

  def operator_display_name
    discord_global_name.presence || discord_username.presence || "未設定ユーザー"
  end

  def manageable_user_types
    return USER_TYPES.keys.map(&:to_s) if admin?
    return [ "reader" ] if operator?

    []
  end

  def create_memory_quota_limit_mb
    return unless operator?

    OPERATOR_CREATE_MEMORY_QUOTA_MB
  end

  def owned_server_memory_mb_total
    owned_minecraft_servers.sum(:memory_mb)
  end

  def remaining_create_memory_quota_mb
    limit = create_memory_quota_limit_mb
    return if limit.blank?

    [ limit - owned_server_memory_mb_total, 0 ].max
  end

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
      last_discord_login_at: Time.current,
    )
  end
end
