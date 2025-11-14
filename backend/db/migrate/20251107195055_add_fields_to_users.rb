class AddFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string, null: false
    add_column :users, :phone, :string
    add_column :users, :role, :string, null: false, default: 'consumer'
    add_column :users, :active, :boolean, default: true
    add_column :users, :last_seen_at, :datetime

    add_index :users, :role
  end
end
