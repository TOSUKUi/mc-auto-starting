class MinecraftServer < ApplicationRecord
  MANAGED_CONTAINER_PORT = 25_565

  STATUS_TRANSITIONS = MinecraftServerStatus::TRANSITIONS

  belongs_to :owner, class_name: "User", inverse_of: :owned_minecraft_servers
  has_one :router_route, dependent: :destroy
  has_many :server_members, dependent: :destroy
  has_many :member_users, through: :server_members, source: :user

  enum :status, MinecraftServerStatus::ENUM, prefix: true

  before_validation :normalize_hostname
  before_validation :assign_managed_resource_names

  validates :name, :hostname, :status, :minecraft_version, :template_kind, :container_name, :volume_name, presence: true
  validates :hostname, hostname_format: true, reserved_hostname: true
  validates :hostname, uniqueness: true
  validates :container_name, :volume_name, uniqueness: true
  validates :memory_mb, :disk_mb, numericality: { only_integer: true, greater_than: 0 }
  validate :status_transition_is_allowed, if: :will_save_change_to_status?

  def self.normalize_hostname(value)
    MinecraftServerHostname.normalize(value).presence
  end

  def fqdn
    MinecraftPublicEndpoint.fqdn_for(hostname)
  end

  def slug
    hostname
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

  def route_should_be_enabled?
    MinecraftServerStatus.route_enabled?(status)
  end

  def can_transition_to?(next_status)
    MinecraftServerStatus.can_transition?(from: status, to: next_status)
  end

  def transition_to!(next_status)
    next_status = next_status.to_sym
    raise ArgumentError, "invalid status transition: #{status} -> #{next_status}" unless can_transition_to?(next_status)

    update!(status: next_status)
  end

  private
    def normalize_hostname
      self.hostname = self.class.normalize_hostname(hostname)
    end

    def assign_managed_resource_names
      return if hostname.blank?

      self.container_name = MinecraftServerHostname.container_name_for(hostname)
      self.volume_name = MinecraftServerHostname.volume_name_for(hostname)
    end

    def status_transition_is_allowed
      previous_status = status_in_database&.to_sym
      next_status = status.to_sym
      return if previous_status.nil?
      return if previous_status == next_status
      return if MinecraftServerStatus.can_transition?(from: previous_status, to: next_status)

      errors.add(:status, "cannot transition from #{previous_status} to #{next_status}")
    end
end
