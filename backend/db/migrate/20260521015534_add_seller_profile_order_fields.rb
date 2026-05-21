class AddSellerProfileOrderFields < ActiveRecord::Migration[8.1]
  def change
    add_column :seller_profiles, :offers_delivery, :boolean, default: false, null: false
    add_column :seller_profiles, :delivery_fee_amount, :decimal, precision: 10, scale: 2
    add_column :seller_profiles, :grace_period_minutes, :integer, default: 30, null: false
  end
end
