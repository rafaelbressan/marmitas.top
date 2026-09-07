class AdoptDiscardAcrossTheOwnershipTree < ActiveRecord::Migration[8.1]
  # `weekly_menus` ja tinha soft delete artesanal em `deleted_at`. O rename
  # preserva os registros que ja estavam apagados: nenhum dado sai do banco e
  # nenhum menu apagado volta a aparecer.
  RENAMED = :weekly_menus

  ADDED = %i[seller_profiles dishes selling_locations reviews].freeze

  def change
    # O rename tambem renomeia o indice no PostgreSQL.
    rename_column RENAMED, :deleted_at, :discarded_at

    ADDED.each do |table|
      add_column table, :discarded_at, :datetime
      add_index table, :discarded_at
    end
  end
end
