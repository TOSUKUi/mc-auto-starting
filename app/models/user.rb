class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :audit_logs, foreign_key: :actor_id, inverse_of: :actor, dependent: :nullify
  has_many :owned_minecraft_servers, class_name: "MinecraftServer", foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_exception
  has_many :server_members, dependent: :destroy
  has_many :member_minecraft_servers, through: :server_members, source: :minecraft_server

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
