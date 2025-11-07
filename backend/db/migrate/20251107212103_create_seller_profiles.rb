class CreateSellerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :seller_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :business_name, null: false
      t.text :bio
      t.string :phone
      t.string :whatsapp
      t.string :city
      t.string :state
      t.jsonb :operating_hours, default: {}
      t.integer :followers_count, default: 0, null: false
      t.decimal :average_rating, precision: 3, scale: 2, default: 0.0
      t.integer :reviews_count, default: 0, null: false
      t.boolean :verified, default: false, null: false
      t.boolean :currently_active, default: false, null: false
      t.datetime :last_active_at

      t.timestamps
    end

    add_index :seller_profiles, :currently_active
    add_index :seller_profiles, :city
    add_index :seller_profiles, :verified
  end
end
