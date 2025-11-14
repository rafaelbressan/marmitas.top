class AddReviewCountersToSellerProfiles < ActiveRecord::Migration[8.1]
  def change
    # Only add columns that don't already exist (average_rating and reviews_count already exist)
    add_column :seller_profiles, :rating_1_count, :integer, default: 0
    add_column :seller_profiles, :rating_2_count, :integer, default: 0
    add_column :seller_profiles, :rating_3_count, :integer, default: 0
    add_column :seller_profiles, :rating_4_count, :integer, default: 0
    add_column :seller_profiles, :rating_5_count, :integer, default: 0

    # Index for sorting/filtering by rating (may already exist, wrapped in if)
    add_index :seller_profiles, :average_rating unless index_exists?(:seller_profiles, :average_rating)
  end
end
