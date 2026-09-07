class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      # Core associations
      t.references :user, null: false, foreign_key: true
      t.references :seller_profile, null: false, foreign_key: true
      t.references :weekly_menu, null: true, foreign_key: true  # Optional - which menu was reviewed

      # Review content
      t.integer :rating, null: false  # 1-5 stars
      t.text :comment  # Optional text review
      t.date :encounter_date, null: false  # When they visited the seller
      t.string :dish_name  # Snapshot of dish name (preserved even if menu deleted)

      # Location verification
      t.decimal :encounter_latitude, precision: 10, scale: 6
      t.decimal :encounter_longitude, precision: 10, scale: 6
      t.boolean :verified_encounter, default: false  # True if coords matched seller location
      t.datetime :encounter_timestamp

      # Moderation
      t.boolean :flagged, default: false
      t.string :flag_reason
      t.string :moderation_status, default: 'published'  # published, under_review, removed
      t.text :moderation_note  # Admin notes
      t.datetime :moderated_at
      t.references :moderated_by, foreign_key: { to_table: :users }, null: true

      # Engagement
      t.integer :helpful_count, default: 0
      t.integer :edit_count, default: 0
      t.datetime :last_edited_at

      t.timestamps
    end

    # Indexes for performance (seller_profile_id, user_id, weekly_menu_id already indexed by references)
    add_index :reviews, :rating
    add_index :reviews, :moderation_status
    add_index :reviews, :flagged
    add_index :reviews, :created_at
    add_index :reviews, :encounter_date

    # Unique constraint: one review per user per seller per day
    add_index :reviews, [:user_id, :seller_profile_id, :encounter_date],
              unique: true,
              name: 'index_reviews_on_user_seller_date'

    # Check constraint: rating must be between 1 and 5
    add_check_constraint :reviews, "rating >= 1 AND rating <= 5", name: "reviews_rating_range"
  end
end
