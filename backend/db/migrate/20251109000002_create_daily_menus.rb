class CreateDailyMenus < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_menus do |t|
      t.references :seller_profile, null: false, foreign_key: true, index: true
      t.string :title
      t.text :description
      t.datetime :available_from, null: false
      t.datetime :available_until, null: false
      t.boolean :active, default: true, null: false
      t.integer :total_orders_count, default: 0, null: false

      t.timestamps
    end

    add_index :daily_menus, [:seller_profile_id, :available_from]
    add_index :daily_menus, :available_from
    add_index :daily_menus, :available_until
    add_index :daily_menus, :active
  end
end
