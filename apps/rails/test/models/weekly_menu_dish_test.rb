require "test_helper"

class WeeklyMenuDishTest < ActiveSupport::TestCase
  setup do
    @menu_dish = weekly_menu_dishes(:marli_feijoada) # 20 disponiveis, 8 restantes
  end

  # A prova de que a concorrencia esta resolvida no banco e nao em Ruby: dois
  # objetos carregados antes de qualquer baixa acham, os dois, que restam 8. Se a
  # guarda estivesse no `if` do Ruby, os dois venderiam 5 — 10 marmitas de um
  # estoque de 8. Com a guarda no WHERE do UPDATE, o segundo nao encontra linha.
  test "duas baixas simultaneas nao passam do estoque" do
    primeiro = WeeklyMenuDish.find(@menu_dish.id)
    segundo = WeeklyMenuDish.find(@menu_dish.id)

    assert_equal 8, primeiro.remaining_quantity
    assert_equal 8, segundo.remaining_quantity

    assert primeiro.sell!(5)
    assert_not segundo.sell!(5)

    assert_equal 3, @menu_dish.reload.remaining_quantity
  end

  test "sell! devolve false e nao muda nada quando falta estoque" do
    assert_not @menu_dish.sell!(9)
    assert_equal 8, @menu_dish.reload.remaining_quantity
  end

  test "sell! zera o estoque quando a baixa e exatamente o que restava" do
    assert @menu_dish.sell!(8)
    assert_equal 0, @menu_dish.reload.remaining_quantity
    assert_not @menu_dish.available?
  end

  test "sell! recusa quantidade nao positiva" do
    assert_raises(ArgumentError) { @menu_dish.sell!(0) }
    assert_raises(ArgumentError) { @menu_dish.sell!(-1) }
    assert_equal 8, @menu_dish.reload.remaining_quantity
  end

  test "set_remaining! nao aceita mais do que o total disponivel" do
    assert_raises(ActiveRecord::RecordInvalid) { @menu_dish.set_remaining!(21) }
    assert_raises(ActiveRecord::RecordInvalid) { @menu_dish.set_remaining!(-1) }
    assert_equal 8, @menu_dish.reload.remaining_quantity
  end
end
