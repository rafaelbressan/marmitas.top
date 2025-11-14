class RenameDailyToWeeklyMenus < ActiveRecord::Migration[8.1]
  def change
    rename_table :daily_menus, :weekly_menus
    rename_table :daily_menu_dishes, :weekly_menu_dishes

    # Rename foreign key column
    rename_column :weekly_menu_dishes, :daily_menu_id, :weekly_menu_id
  end
end
