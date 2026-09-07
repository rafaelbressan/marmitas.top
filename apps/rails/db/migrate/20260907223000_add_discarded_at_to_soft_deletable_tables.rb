# Deletar vira descartar. As cinco tabelas que guardam historico ganham
# `discarded_at`; nenhuma linha sai mais do banco.
#
# `weekly_menus` ja tinha `deleted_at`, escrito a mao por um `destroy`
# sobrescrito no model. A coluna e renomeada em vez de recriada para nao perder
# o que ja foi apagado, e o indice antigo vem junto no rename.
class AddDiscardedAtToSoftDeletableTables < ActiveRecord::Migration[8.1]
  TABLES = %i[seller_profiles dishes selling_locations reviews].freeze

  def up
    rename_column :weekly_menus, :deleted_at, :discarded_at

    TABLES.each do |table|
      add_column table, :discarded_at, :datetime
      add_index table, :discarded_at
    end
  end

  def down
    TABLES.reverse_each do |table|
      remove_index table, :discarded_at
      remove_column table, :discarded_at
    end

    rename_column :weekly_menus, :discarded_at, :deleted_at
  end
end
