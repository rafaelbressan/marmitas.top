class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :favoritable, polymorphic: true, null: false

      t.timestamps
    end

    # Prevent duplicate favorites
    add_index :favorites, [:user_id, :favoritable_type, :favoritable_id], unique: true, name: 'index_favorites_uniqueness'

    # Add favorites counter cache to seller_profiles and dishes
    add_column :seller_profiles, :favorites_count, :integer, default: 0, null: false
    add_column :dishes, :favorites_count, :integer, default: 0, null: false
  end
end
