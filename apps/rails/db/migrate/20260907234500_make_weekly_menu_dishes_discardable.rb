# A linha de `weekly_menu_dishes` e o registro do dia: `available_quantity` e
# `remaining_quantity` dizem quanto foi anunciado e quanto sobrou. Tirar um prato
# do cardapio apagava essa linha — a mesma perda que BRES-140 fecha nas outras
# tabelas.
#
# O indice unico vira parcial: um prato removido e recolocado no mesmo cardapio
# esbarraria na linha antiga, que agora continua no banco.
class MakeWeeklyMenuDishesDiscardable < ActiveRecord::Migration[8.1]
  UNIQUE_KEPT = "index_weekly_menu_dishes_on_menu_and_dish_kept".freeze

  def up
    add_column :weekly_menu_dishes, :discarded_at, :datetime
    add_index :weekly_menu_dishes, :discarded_at

    remove_index :weekly_menu_dishes, column: [ :weekly_menu_id, :dish_id ], unique: true
    add_index :weekly_menu_dishes, [ :weekly_menu_id, :dish_id ],
              unique: true, where: "discarded_at IS NULL", name: UNIQUE_KEPT
  end

  def down
    remove_index :weekly_menu_dishes, name: UNIQUE_KEPT
    add_index :weekly_menu_dishes, [ :weekly_menu_id, :dish_id ], unique: true

    remove_index :weekly_menu_dishes, column: :discarded_at
    remove_column :weekly_menu_dishes, :discarded_at
  end
end
