class AddInvitedUserTypeToDiscordInvitations < ActiveRecord::Migration[8.1]
  def change
    add_column :discord_invitations, :invited_user_type, :string, null: false, default: "reader"
    add_index :discord_invitations, :invited_user_type
  end
end
