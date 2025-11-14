class CreateDailyMenuDishes < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_menu_dishes do |t|
      t.references :daily_menu, null: false, foreign_key: true, index: true
      t.references :dish, null: false, foreign_key: true, index: true
      t.integer :available_quantity, null: false
      t.integer :remaining_quantity, null: false
      t.decimal :price_override, precision: 10, scale: 2
      t.integer :display_order, default: 0

      t.timestamps
    end

    add_index :daily_menu_dishes, [:daily_menu_id, :dish_id], unique: true
    add_index :daily_menu_dishes, :display_order
  end
end
