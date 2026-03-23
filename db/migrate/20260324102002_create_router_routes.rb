class CreateRouterRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :router_routes do |t|
      t.references :minecraft_server, null: false, foreign_key: true, index: { unique: true }
      t.boolean :enabled, null: false, default: false
      t.string :last_apply_status, null: false, default: "pending"
      t.datetime :last_applied_at
      t.string :last_healthcheck_status, null: false, default: "unknown"
      t.datetime :last_healthchecked_at

      t.timestamps
    end

    add_index :router_routes, :enabled
    add_index :router_routes, :last_apply_status
    add_index :router_routes, :last_healthcheck_status
  end
end
