class CreateDiscordInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :discord_invitations do |t|
      t.string :token_digest, null: false
      t.string :discord_user_id, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.datetime :revoked_at
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :note

      t.timestamps
    end

    add_index :discord_invitations, :token_digest, unique: true
    add_index :discord_invitations, :discord_user_id
  end
end
