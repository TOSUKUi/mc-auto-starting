class CreateServerJob < ApplicationJob
  queue_as :default

  def perform(server_id)
    server = MinecraftServer.find_by(id: server_id)
    return if server.nil?

    Servers::ProvisionServer.new(server: server).call
  end
end
