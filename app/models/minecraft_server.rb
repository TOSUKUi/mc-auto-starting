class MinecraftServer < ApplicationRecord
  belongs_to :owner, class_name: "User", inverse_of: :owned_minecraft_servers

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

  validates :name, :hostname, :status, :provider_name, :minecraft_version, :template_kind, presence: true
  validates :hostname, hostname_format: true, reserved_hostname: true
  validates :hostname, uniqueness: true
  validates :memory_mb, :disk_mb, numericality: { only_integer: true, greater_than: 0 }
  validates :backend_port, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 65_535 }, allow_nil: true

  def fqdn
    MinecraftPublicEndpoint.fqdn_for(hostname)
  end

  def connection_target
    MinecraftPublicEndpoint.connection_target_for(hostname)
  end

  private
    def normalize_hostname
      self.hostname = hostname.to_s.strip.downcase
    end
end
