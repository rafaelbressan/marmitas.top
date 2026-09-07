class CreateDeviceTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :device_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.string :platform, null: false # 'ios', 'android', 'web'
      t.string :device_name
      t.boolean :active, default: true, null: false
      t.datetime :last_used_at

      t.timestamps
    end

    # Ensure unique tokens per user and platform
    add_index :device_tokens, [:user_id, :token, :platform], unique: true, name: 'index_device_tokens_uniqueness'
    add_index :device_tokens, :token

    # Add notification preferences to users
    add_column :users, :notification_preferences, :jsonb, default: {
      seller_arrivals: true,
      new_menus: true,
      order_updates: true,
      promotions: false
    }, null: false
  end
end
