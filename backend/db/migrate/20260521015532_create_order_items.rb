class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      # Associations
      t.references :order, null: false, foreign_key: true, index: true
      t.references :dish, null: false, foreign_key: true, index: true
      t.references :weekly_menu_dish, foreign_key: true, index: true

      # Quantity and pricing
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :subtotal, precision: 10, scale: 2, null: false

      # Data snapshot for historical accuracy
      t.string :dish_name_snapshot, null: false
      t.text :dish_description_snapshot

      t.timestamps
    end

    # Ensure quantity is positive
    add_check_constraint :order_items,
      "quantity > 0",
      name: 'order_items_quantity_positive'
  end
end
