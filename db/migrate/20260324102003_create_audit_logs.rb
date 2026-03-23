class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :minecraft_server, null: false, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }
      t.string :event_type, null: false
      t.json :payload, null: false, default: {}

      t.timestamps
    end

    add_index :audit_logs, [ :minecraft_server_id, :created_at ]
    add_index :audit_logs, [ :minecraft_server_id, :event_type ]
    add_index :audit_logs, [ :actor_id, :created_at ]
  end
end
