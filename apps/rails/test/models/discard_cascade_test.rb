require "test_helper"

# Deletar virou descartar. Este arquivo prova as duas metades da decisao:
# a cascata desce pela arvore de dono, e nenhuma linha sai do banco.
class DiscardCascadeTest < ActiveSupport::TestCase
  setup { @marli = seller_profiles(:marli_marmitas) }

  test "descartar o marmiteiro desce para prato, cardapio, ponto de venda e avaliacao" do
    @marli.discard

    assert_empty @marli.dishes.kept
    assert_empty @marli.weekly_menus.kept
    assert_empty @marli.selling_locations.kept
    assert_empty @marli.reviews.kept
  end

  test "descartar nao apaga linha nenhuma do banco" do
    antes = contagens

    @marli.discard

    assert_equal antes, contagens
    assert_predicate dishes(:feijoada).reload, :discarded?
  end

  test "o marmiteiro descartado some da vitrine e do mapa" do
    assert_includes SellerProfile.kept.verified, @marli

    @marli.discard

    assert_not_includes SellerProfile.kept.verified, @marli
    assert_not_includes SellerProfile.kept.verified.nearby(-22.9295, -43.1774, 5), @marli
    assert_not_includes WeeklyMenu.active.available_now, weekly_menus(:marli_semana_atual)
    assert_not_includes Review.published, reviews(:carla_sobre_marli)
  end

  test "o marmiteiro do lado nao e levado junto" do
    @marli.discard

    assert_predicate dishes(:carne_de_panela).reload, :kept?
    assert_predicate weekly_menus(:jorge_semana_atual).reload, :kept?
    assert_predicate selling_locations(:rua_do_catete).reload, :kept?
  end

  test "voltar atras restaura o que a cascata descartou" do
    @marli.discard
    @marli.undiscard

    assert_predicate dishes(:feijoada).reload, :kept?
    assert_predicate weekly_menus(:marli_semana_atual).reload, :kept?
    assert_predicate selling_locations(:largo_do_machado).reload, :kept?
    assert_predicate reviews(:carla_sobre_marli).reload, :kept?
  end

  # A cascata carimba os filhos com o `discarded_at` exato do perfil justamente
  # para isto: o prato que o marmiteiro ja tinha tirado do cardapio antes nao
  # volta sozinho quando o perfil volta.
  test "voltar atras nao ressuscita o que ja estava descartado antes" do
    dishes(:frango_grelhado).discard

    @marli.discard
    @marli.undiscard

    assert_predicate dishes(:feijoada).reload, :kept?
    assert_predicate dishes(:frango_grelhado).reload, :discarded?
  end

  # O caso que abriu a discussao: apagar o prato apagava a linha dele em todo
  # cardapio passado, e e essa linha que guarda quanto saiu naquele dia.
  test "descartar um prato preserva a baixa dele nos cardapios passados" do
    linha = weekly_menu_dishes(:marli_feijoada_semana_passada)

    dishes(:feijoada).discard

    assert_predicate linha.reload, :kept?
    assert_equal 25, linha.available_quantity
    assert_equal 0, linha.remaining_quantity
  end

  test "tirar um prato do cardapio descarta a linha em vez de apagar" do
    linha = weekly_menu_dishes(:marli_feijoada)
    antes = WeeklyMenuDish.count

    linha.discard

    assert_equal antes, WeeklyMenuDish.count
    assert_not_includes weekly_menus(:marli_semana_atual).weekly_menu_dishes.ordered, linha
  end

  # O indice unico virou parcial (`WHERE discarded_at IS NULL`) por causa deste
  # caso: sem isso, recolocar o prato esbarraria na linha antiga.
  test "prato tirado e recolocado no mesmo cardapio cria linha nova" do
    menu = weekly_menus(:marli_semana_atual)
    weekly_menu_dishes(:marli_feijoada).discard

    nova = menu.weekly_menu_dishes.create!(
      dish: dishes(:feijoada), available_quantity: 12, display_order: 0
    )

    assert_predicate nova, :persisted?
    assert_equal 2, menu.weekly_menu_dishes.where(dish: dishes(:feijoada)).count
  end

  private
    def contagens
      [ SellerProfile, Dish, WeeklyMenu, SellingLocation, Review, WeeklyMenuDish ].index_with(&:count)
    end
end
