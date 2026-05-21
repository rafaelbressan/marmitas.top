class AddOrderCounters < ActiveRecord::Migration[8.1]
  def change
    # Add to seller_profiles
    add_column :seller_profiles, :total_orders_count, :integer, default: 0, null: false
    add_column :seller_profiles, :completed_orders_count, :integer, default: 0, null: false

    # Add to users
    add_column :users, :orders_count, :integer, default: 0, null: false

    # Add index for seller stats
    add_index :seller_profiles, :total_orders_count
  end
end
