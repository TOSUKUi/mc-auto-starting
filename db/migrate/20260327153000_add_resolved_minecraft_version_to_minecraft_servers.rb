class AddResolvedMinecraftVersionToMinecraftServers < ActiveRecord::Migration[8.1]
  def up
    add_column :minecraft_servers, :resolved_minecraft_version, :string

    execute <<~SQL.squish
      UPDATE minecraft_servers
      SET resolved_minecraft_version = minecraft_version
      WHERE resolved_minecraft_version IS NULL
    SQL
  end

  def down
    remove_column :minecraft_servers, :resolved_minecraft_version
  end
end
