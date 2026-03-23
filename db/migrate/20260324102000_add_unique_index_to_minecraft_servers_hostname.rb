class AddUniqueIndexToMinecraftServersHostname < ActiveRecord::Migration[8.1]
  def change
    add_index :minecraft_servers, :hostname, unique: true
  end
end
