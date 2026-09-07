class AddLocationBroadcastToSellerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_reference :seller_profiles, :current_location, foreign_key: { to_table: :selling_locations }, index: true
    add_column :seller_profiles, :arrived_at, :datetime
    add_column :seller_profiles, :leaving_at, :datetime

    add_index :seller_profiles, :arrived_at
    add_index :seller_profiles, :leaving_at
  end
end
