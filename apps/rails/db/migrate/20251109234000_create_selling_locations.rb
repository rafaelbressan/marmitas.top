class CreateSellingLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :selling_locations do |t|
      t.references :seller_profile, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :address
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.text :notes

      t.timestamps
    end

    add_index :selling_locations, [:seller_profile_id, :name]
  end
end
