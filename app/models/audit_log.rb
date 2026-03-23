class AuditLog < ApplicationRecord
  belongs_to :minecraft_server
  belongs_to :actor, class_name: "User", optional: true

  attribute :payload, :json, default: -> { {} }

  normalizes :event_type, with: ->(value) { value.to_s.strip }

  validates :event_type, presence: true
  validate :payload_must_be_present

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  private
    def payload_must_be_present
      errors.add(:payload, "can't be blank") if payload.nil?
    end
end
