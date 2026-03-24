class AddProviderServerIdentifierToMinecraftServers < ActiveRecord::Migration[8.1]
  def change
    add_column :minecraft_servers, :provider_server_identifier, :string
  end
end
