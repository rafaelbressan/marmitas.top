class CreateDishes < ActiveRecord::Migration[8.1]
  def change
    create_table :dishes do |t|
      t.references :seller_profile, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.decimal :base_price, precision: 10, scale: 2, null: false
      t.jsonb :dietary_tags, default: []
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :dishes, [:seller_profile_id, :name]
    add_index :dishes, :active
  end
end
