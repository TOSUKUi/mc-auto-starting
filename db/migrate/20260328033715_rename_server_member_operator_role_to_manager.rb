class RenameServerMemberOperatorRoleToManager < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE server_members
      SET role = 'manager'
      WHERE role = 'operator'
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE server_members
      SET role = 'operator'
      WHERE role = 'manager'
    SQL
  end
end
