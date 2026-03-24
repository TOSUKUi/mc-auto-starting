class CreateServerJob < ApplicationJob
  queue_as :default

  def perform(server_id)
    server = MinecraftServer.find_by(id: server_id)
    return if server.nil?

    # T-500 only guarantees request intake plus enqueue.
    # T-501 will replace this placeholder with provider provisioning and route apply.
    server
  end
end
