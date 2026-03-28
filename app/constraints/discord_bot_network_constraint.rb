require "ipaddr"

class DiscordBotNetworkConstraint
  def initialize(cidrs: Rails.application.config.x.discord_bot.allowed_cidrs)
    @allowed_networks = Array(cidrs).map { |cidr| IPAddr.new(cidr) }
  end

  def matches?(request)
    remote_ip = request.remote_ip
    return false if remote_ip.blank?

    ip = IPAddr.new(remote_ip)
    allowed_networks.any? { |network| network.include?(ip) }
  rescue IPAddr::InvalidAddressError
    false
  end

  private
    attr_reader :allowed_networks
end
