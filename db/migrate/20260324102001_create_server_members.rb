class CreateServerMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :server_members do |t|
      t.references :minecraft_server, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end

    add_index :server_members, [ :minecraft_server_id, :user_id ], unique: true
  end
end
