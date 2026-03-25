class AddDirectDockerFieldsToMinecraftServers < ActiveRecord::Migration[8.1]
  class MigrationMinecraftServer < ActiveRecord::Base
    self.table_name = "minecraft_servers"
  end

  def up
    add_column :minecraft_servers, :container_name, :string
    add_column :minecraft_servers, :container_id, :string
    add_column :minecraft_servers, :volume_name, :string
    add_column :minecraft_servers, :container_state, :string
    add_column :minecraft_servers, :last_started_at, :datetime
    change_column_null :minecraft_servers, :provider_name, true

    MigrationMinecraftServer.reset_column_information

    say_with_time "Backfilling managed Docker resource names" do
      MigrationMinecraftServer.find_each do |server|
        hostname = server.hostname.to_s.strip.downcase

        server.update_columns(
          hostname: hostname,
          container_name: "mc-server-#{hostname}",
          volume_name: "mc-data-#{hostname}",
        )
      end
    end

    change_column_null :minecraft_servers, :container_name, false
    change_column_null :minecraft_servers, :volume_name, false

    add_index :minecraft_servers, :container_name, unique: true
    add_index :minecraft_servers, :volume_name, unique: true
    add_index :minecraft_servers, :container_id
    add_index :minecraft_servers, :container_state
  end

  def down
    MigrationMinecraftServer.reset_column_information
    MigrationMinecraftServer.where(provider_name: nil).update_all(provider_name: "legacy_provider")

    remove_index :minecraft_servers, :container_state
    remove_index :minecraft_servers, :container_id
    remove_index :minecraft_servers, :volume_name
    remove_index :minecraft_servers, :container_name

    change_column_null :minecraft_servers, :provider_name, false

    remove_column :minecraft_servers, :last_started_at, :datetime
    remove_column :minecraft_servers, :container_state, :string
    remove_column :minecraft_servers, :volume_name, :string
    remove_column :minecraft_servers, :container_id, :string
    remove_column :minecraft_servers, :container_name, :string
  end
end
