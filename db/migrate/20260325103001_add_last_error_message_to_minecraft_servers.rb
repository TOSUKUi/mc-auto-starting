class AddLastErrorMessageToMinecraftServers < ActiveRecord::Migration[8.1]
  def change
    add_column :minecraft_servers, :last_error_message, :string
  end
end
