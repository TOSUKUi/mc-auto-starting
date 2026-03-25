module MinecraftServerStatus
  TRANSITIONS = {
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

  ROUTE_ENABLED_STATUSES = %i[ready stopped starting stopping restarting degraded].freeze
  ENUM = TRANSITIONS.keys.index_with(&:to_s).freeze

  module_function

  def can_transition?(from:, to:)
    from = from.to_sym
    to = to.to_sym
    return true if from == to

    TRANSITIONS.fetch(from).include?(to)
  end

  def route_enabled?(status)
    ROUTE_ENABLED_STATUSES.include?(status.to_sym)
  end
end
