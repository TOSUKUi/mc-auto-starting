class MinecraftServer < ApplicationRecord
  LEGACY_TEMPLATE_KIND = "paper"
  RUNTIME_FAMILIES = %w[paper vanilla].freeze
  DIFFICULTIES = %w[peaceful easy normal hard].freeze
  GAMEMODES = %w[survival creative adventure spectator].freeze
  MANAGED_CONTAINER_PORT = 25_565
  MIN_MEMORY_MB = 512
  MAX_MEMORY_MB = 4096
  MIN_MAX_PLAYERS = 1
  MAX_MAX_PLAYERS = 100
  PLAYER_NAME_PATTERN = /\A[A-Za-z0-9_]{3,16}\z/

  STATUS_TRANSITIONS = MinecraftServerStatus::TRANSITIONS

  belongs_to :owner, class_name: "User", inverse_of: :owned_minecraft_servers
  has_one :router_route, dependent: :destroy
  has_many :server_members, dependent: :destroy
  has_many :member_users, through: :server_members, source: :user

  enum :status, MinecraftServerStatus::ENUM, prefix: true

  before_validation :normalize_hostname
  before_validation :assign_legacy_template_kind
  before_validation :assign_managed_resource_names
  before_validation :normalize_whitelist_entries

  validates :name, :hostname, :status, :minecraft_version, :template_kind, :container_name, :volume_name, presence: true
  validates :template_kind, inclusion: { in: RUNTIME_FAMILIES }
  validates :difficulty, inclusion: { in: DIFFICULTIES }
  validates :gamemode, inclusion: { in: GAMEMODES }
  validates :hostname, hostname_format: true, reserved_hostname: true
  validates :hostname, uniqueness: true
  validates :container_name, :volume_name, uniqueness: true
  validates :memory_mb, numericality: {
    only_integer: true,
    greater_than_or_equal_to: MIN_MEMORY_MB,
    less_than_or_equal_to: MAX_MEMORY_MB,
  }
  validates :disk_mb, numericality: { only_integer: true, greater_than: 0 }
  validates :max_players, numericality: {
    only_integer: true,
    greater_than_or_equal_to: MIN_MAX_PLAYERS,
    less_than_or_equal_to: MAX_MAX_PLAYERS,
  }
  validates :motd, length: { maximum: 255 }
  validates :hardcore, :pvp, inclusion: { in: [ true, false ] }
  validate :whitelist_entries_are_valid
  validate :status_transition_is_allowed, if: :will_save_change_to_status?

  def self.normalize_hostname(value)
    MinecraftServerHostname.normalize(value).presence
  end

  def fqdn
    MinecraftPublicEndpoint.fqdn_for(hostname)
  end

  def runtime_family
    template_kind.presence || LEGACY_TEMPLATE_KIND
  end

  def display_minecraft_version
    resolved_minecraft_version.presence || minecraft_version
  end

  def startup_settings
    {
      hardcore: hardcore?,
      difficulty: difficulty,
      gamemode: gamemode,
      max_players: max_players,
      motd: motd.to_s,
      pvp: pvp?,
    }
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

  def rcon_host
    MinecraftRcon.host_for(self)
  end

  def rcon_port
    MinecraftRcon.port
  end

  def rcon_password
    MinecraftRcon.password_for(self)
  end

  def whitelist_entries
    raw_entries = self[:whitelist_entries]
    return [] if raw_entries.blank?
    return raw_entries if raw_entries.is_a?(Array)

    JSON.parse(raw_entries)
  rescue JSON::ParserError
    []
  end

  def whitelist_entries=(value)
    normalized_entries = Array(value)
      .map { |entry| entry.to_s.strip }
      .reject(&:blank?)
      .uniq
      .sort

    self[:whitelist_entries] = JSON.generate(normalized_entries)
  end

  def whitelist_entries_csv
    whitelist_entries.join(",")
  end

  def whitelist_entry?(player_name)
    whitelist_entries.include?(player_name.to_s.strip)
  end

  def hardcore?
    !!self[:hardcore]
  end

  def pvp?
    !!self[:pvp]
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

    def assign_legacy_template_kind
      self.template_kind = LEGACY_TEMPLATE_KIND if template_kind.blank?
    end

    def assign_managed_resource_names
      return if hostname.blank?

      self.container_name = MinecraftServerHostname.container_name_for(hostname)
      self.volume_name = MinecraftServerHostname.volume_name_for(hostname)
    end

    def normalize_whitelist_entries
      self.whitelist_entries = Array(whitelist_entries)
        .map { |entry| entry.to_s.strip }
        .reject(&:blank?)
        .uniq
        .sort
    end

    def whitelist_entries_are_valid
      whitelist_entries.each do |entry|
        next if entry.match?(PLAYER_NAME_PATTERN)

        errors.add(:whitelist_entries, "contains an invalid player name: #{entry}")
      end
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
