class StopStoringUserEmails < ActiveRecord::Migration[8.1]
  def up
    change_column_null :users, :email_address, true
    remove_column :users, :discord_email, :string

    execute("UPDATE users SET email_address = NULL")
  end

  def down
    add_column :users, :discord_email, :string

    execute(<<~SQL.squish)
      UPDATE users
      SET email_address = CONCAT('restored-user-', id, '@example.invalid')
      WHERE email_address IS NULL
    SQL

    change_column_null :users, :email_address, false
  end
end
