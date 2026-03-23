class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :owned_minecraft_servers, class_name: "MinecraftServer", foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_exception

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
