# A linha de `weekly_menu_dishes` e o registro do que foi vendido naquele dia:
# `available_quantity` e `remaining_quantity` sao a baixa do prato. Tirar um
# prato do cardapio apagava essa linha.
#
# O indice unico vira parcial. Sem isso, um prato removido e recolocado no mesmo
# cardapio esbarraria na linha antiga, que agora continua no banco.
class MakeWeeklyMenuDishesDiscardable < ActiveRecord::Migration[8.1]
  def up
    add_column :weekly_menu_dishes, :discarded_at, :datetime
    add_index :weekly_menu_dishes, :discarded_at

    remove_index :weekly_menu_dishes, column: [ :weekly_menu_id, :dish_id ], unique: true
    add_index :weekly_menu_dishes, [ :weekly_menu_id, :dish_id ],
      unique: true,
      where: "discarded_at IS NULL",
      name: "index_weekly_menu_dishes_on_menu_and_dish_kept"
  end

  def down
    remove_index :weekly_menu_dishes, name: "index_weekly_menu_dishes_on_menu_and_dish_kept"
    add_index :weekly_menu_dishes, [ :weekly_menu_id, :dish_id ], unique: true

    remove_index :weekly_menu_dishes, :discarded_at
    remove_column :weekly_menu_dishes, :discarded_at
  end
end
