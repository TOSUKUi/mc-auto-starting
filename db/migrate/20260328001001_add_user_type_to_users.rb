class AddUserTypeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :user_type, :string, null: false, default: "reader"
    add_index :users, :user_type

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE users
          SET user_type = 'operator'
          WHERE user_type = 'reader'
        SQL
      end
    end
  end
end
