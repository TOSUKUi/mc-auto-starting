class RouterRoute < ApplicationRecord
  belongs_to :minecraft_server

  attribute :enabled, :boolean, default: false
  PUBLICATION_STATES = %w[unpublished pending published failed invalid].freeze

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

  delegate :backend, :fqdn, :route_should_be_enabled?, to: :minecraft_server

  def server_address
    fqdn
  end

  def desired_enabled?
    route_should_be_enabled?
  end

  def publishable?
    enabled? && desired_enabled? && server_address.present? && backend.present?
  end

  def publication_state
    return "unpublished" unless enabled?
    return "failed" if last_apply_status_failed?
    return "invalid" unless desired_enabled? && server_address.present? && backend.present?
    return "pending" if last_apply_status_pending?

    "published"
  end
end
