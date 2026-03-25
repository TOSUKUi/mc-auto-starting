class MinecraftServer < ApplicationRecord
  MANAGED_CONTAINER_PORT = 25_565

  STATUS_TRANSITIONS = {
    provisioning: %i[ready failed unpublished deleting],
    ready: %i[starting stopping restarting degraded unpublished deleting failed],
    stopped: %i[starting deleting failed],
    starting: %i[ready failed degraded stopping],
    stopping: %i[stopped failed degraded],
    restarting: %i[ready failed degraded],
    degraded: %i[ready restarting stopping unpublished failed deleting],
    unpublished: %i[provisioning ready deleting failed],
    failed: %i[provisioning deleting],
    deleting: [],
  }.freeze

  belongs_to :owner, class_name: "User", inverse_of: :owned_minecraft_servers
  has_one :router_route, dependent: :destroy
  has_many :server_members, dependent: :destroy
  has_many :member_users, through: :server_members, source: :user

  enum :status, {
    provisioning: "provisioning",
    ready: "ready",
    stopped: "stopped",
    starting: "starting",
    stopping: "stopping",
    restarting: "restarting",
    degraded: "degraded",
    unpublished: "unpublished",
    failed: "failed",
    deleting: "deleting",
  }, prefix: true

  before_validation :normalize_hostname
  before_validation :assign_managed_resource_names

  validates :name, :hostname, :status, :minecraft_version, :template_kind, :container_name, :volume_name, presence: true
  validates :hostname, hostname_format: true, reserved_hostname: true
  validates :hostname, uniqueness: true
  validates :container_name, :volume_name, uniqueness: true
  validates :memory_mb, :disk_mb, numericality: { only_integer: true, greater_than: 0 }
  validate :status_transition_is_allowed, if: :will_save_change_to_status?

  def fqdn
    MinecraftPublicEndpoint.fqdn_for(hostname)
  end

  def connection_target
    MinecraftPublicEndpoint.connection_target_for(hostname)
  end

  def backend_host
    container_name
  end

  def backend_port
    MANAGED_CONTAINER_PORT
  end

  def backend
    return if container_name.blank?

    "#{container_name}:#{MANAGED_CONTAINER_PORT}"
  end

  def lifecycle_ready?
    container_id.present?
  end

  def can_transition_to?(next_status)
    next_status = next_status.to_sym
    return true if next_status == status.to_sym

    STATUS_TRANSITIONS.fetch(status.to_sym).include?(next_status)
  end

  def transition_to!(next_status)
    next_status = next_status.to_sym
    raise ArgumentError, "invalid status transition: #{status} -> #{next_status}" unless can_transition_to?(next_status)

    update!(status: next_status)
  end

  private
    def normalize_hostname
      self.hostname = hostname.to_s.strip.downcase
    end

    def assign_managed_resource_names
      return if hostname.blank?

      self.container_name = "mc-server-#{hostname}"
      self.volume_name = "mc-data-#{hostname}"
    end

    def status_transition_is_allowed
      previous_status = status_in_database&.to_sym
      next_status = status.to_sym
      return if previous_status.nil?
      return if previous_status == next_status
      return if STATUS_TRANSITIONS.fetch(previous_status).include?(next_status)

      errors.add(:status, "cannot transition from #{previous_status} to #{next_status}")
    end
end
