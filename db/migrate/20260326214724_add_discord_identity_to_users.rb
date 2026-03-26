class AddDiscordIdentityToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :discord_user_id, :string
    add_column :users, :discord_username, :string
    add_column :users, :discord_global_name, :string
    add_column :users, :discord_avatar, :string
    add_column :users, :discord_email, :string
    add_column :users, :last_discord_login_at, :datetime

    add_index :users, :discord_user_id, unique: true
  end
end
