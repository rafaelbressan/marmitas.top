class RefactorUserRoles < ActiveRecord::Migration[8.1]
  def change
    # Add is_admin boolean instead of using role for admin
    add_column :users, :is_admin, :boolean, default: false, null: false

    # Make role nullable - we'll phase it out
    # Users are consumers by default, sellers if they have a seller_profile
    change_column_null :users, :role, true
    change_column_default :users, :role, from: 'consumer', to: nil

    # Update existing admin users
    reversible do |dir|
      dir.up do
        execute "UPDATE users SET is_admin = true WHERE role = 'admin'"
        execute "UPDATE users SET role = NULL WHERE role = 'consumer' OR role = 'marmiteiro'"
      end

      dir.down do
        execute "UPDATE users SET role = 'admin' WHERE is_admin = true"
        execute "UPDATE users SET role = 'consumer' WHERE role IS NULL AND is_admin = false"
      end
    end
  end
end
