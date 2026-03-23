class ServerMember < ApplicationRecord
  belongs_to :minecraft_server
  belongs_to :user

  enum :role, {
    viewer: "viewer",
    operator: "operator",
  }, prefix: true

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :minecraft_server_id }
  validate :user_is_not_server_owner

  private
    def user_is_not_server_owner
      return if minecraft_server.blank? || user_id.blank?
      return unless minecraft_server.owner_id == user_id

      errors.add(:user_id, "cannot duplicate the server owner")
    end
end
