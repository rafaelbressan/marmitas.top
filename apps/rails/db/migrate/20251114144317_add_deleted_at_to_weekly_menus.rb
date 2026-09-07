class AddDeletedAtToWeeklyMenus < ActiveRecord::Migration[8.1]
  def change
    add_column :weekly_menus, :deleted_at, :datetime
    add_index :weekly_menus, :deleted_at
  end
end
