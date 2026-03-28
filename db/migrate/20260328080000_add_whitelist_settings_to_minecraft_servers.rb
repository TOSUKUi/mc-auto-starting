class AddWhitelistSettingsToMinecraftServers < ActiveRecord::Migration[8.1]
  def change
    add_column :minecraft_servers, :whitelist_enabled, :boolean, null: false, default: true
    add_column :minecraft_servers, :whitelist_entries, :text, null: false
  end
end
