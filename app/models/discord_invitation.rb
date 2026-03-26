class DiscordInvitation < ApplicationRecord
  TOKEN_BYTES = 32

  belongs_to :invited_by, class_name: "User"

  normalizes :discord_user_id, with: ->(value) { value.present? ? value.to_s.strip : nil }
  normalizes :note, with: ->(value) { value.present? ? value.to_s.strip : nil }

  validates :token_digest, presence: true, uniqueness: true
  validates :discord_user_id, presence: true, format: { with: /\A\d+\z/, message: "must be a Discord user ID" }
  validates :expires_at, presence: true
  validate :expires_at_is_in_future, on: :create

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def self.issue!(invited_by:, discord_user_id:, expires_at:, note: nil)
    raw_token = SecureRandom.urlsafe_base64(TOKEN_BYTES)
    invitation = create!(
      invited_by: invited_by,
      discord_user_id: discord_user_id,
      expires_at: expires_at,
      note: note,
      token_digest: digest_token(raw_token),
    )

    [ invitation, raw_token ]
  end

  def self.digest_token(raw_token)
    OpenSSL::Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def status
    return "revoked" if revoked?
    return "used" if used?
    return "expired" if expired?

    "active"
  end

  def active?
    status == "active"
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def used?
    used_at.present?
  end

  def revoke!
    return if revoked?

    update!(revoked_at: Time.current)
  end

  private
    def expires_at_is_in_future
      return if expires_at.blank?
      return if expires_at > Time.current

      errors.add(:expires_at, "must be in the future")
    end
end
