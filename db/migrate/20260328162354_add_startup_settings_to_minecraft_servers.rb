class AddStartupSettingsToMinecraftServers < ActiveRecord::Migration[8.1]
  def change
    add_column :minecraft_servers, :hardcore, :boolean, default: false, null: false
    add_column :minecraft_servers, :difficulty, :string, default: "easy", null: false
    add_column :minecraft_servers, :gamemode, :string, default: "survival", null: false
    add_column :minecraft_servers, :max_players, :integer, default: 20, null: false
    add_column :minecraft_servers, :motd, :string
    add_column :minecraft_servers, :pvp, :boolean, default: true, null: false
  end
end
