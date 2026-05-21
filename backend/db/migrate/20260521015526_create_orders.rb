class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      # Associations
      t.references :user, null: false, foreign_key: true, index: true
      t.references :seller_profile, null: false, foreign_key: true, index: true
      t.references :weekly_menu, foreign_key: true, index: true

      # Order metadata
      t.string :status, null: false, default: 'pending'
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.decimal :delivery_fee, precision: 10, scale: 2, default: 0.0
      t.string :completion_code, limit: 6

      # Timestamps
      t.datetime :order_date, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :pickup_expires_at
      t.datetime :confirmed_at
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.datetime :expired_at
      t.datetime :archived_at

      # Cancellation info
      t.text :cancellation_reason

      # Location snapshots
      t.string :seller_location_name
      t.decimal :seller_latitude, precision: 10, scale: 6
      t.decimal :seller_longitude, precision: 10, scale: 6
      t.decimal :customer_latitude, precision: 10, scale: 6
      t.decimal :customer_longitude, precision: 10, scale: 6

      t.timestamps
    end

    # Additional indexes for common queries
    add_index :orders, :status
    add_index :orders, :order_date
    add_index :orders, :pickup_expires_at
    add_index :orders, [:user_id, :order_date]
    add_index :orders, [:seller_profile_id, :status]
    add_index :orders, [:seller_profile_id, :order_date]

    # Check constraint for valid status values
    add_check_constraint :orders,
      "status IN ('pending', 'confirmed', 'completed', 'cancelled', 'expired')",
      name: 'orders_status_check'
  end
end
