class CreateMinecraftServers < ActiveRecord::Migration[8.1]
  def change
    create_table :minecraft_servers do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :hostname, null: false
      t.string :status, null: false, default: "provisioning"
      t.string :provider_name, null: false
      t.string :provider_server_id
      t.string :backend_host
      t.integer :backend_port
      t.string :minecraft_version, null: false
      t.integer :memory_mb, null: false
      t.integer :disk_mb, null: false
      t.string :template_kind, null: false

      t.timestamps
    end

    add_index :minecraft_servers, :status
    add_index :minecraft_servers, [ :provider_name, :provider_server_id ]
  end
end
