class RouterRoute < ApplicationRecord
  belongs_to :minecraft_server

  attribute :enabled, :boolean, default: false

  enum :last_apply_status, {
    pending: "pending",
    success: "success",
    failed: "failed",
  }, prefix: true, default: :pending

  enum :last_healthcheck_status, {
    unknown: "unknown",
    healthy: "healthy",
    unreachable: "unreachable",
    rejected: "rejected",
  }, prefix: true, default: :unknown

  validates :last_apply_status, :last_healthcheck_status, presence: true
  validates :minecraft_server_id, uniqueness: true
end
