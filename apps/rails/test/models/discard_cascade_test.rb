require "test_helper"

# BRES-140: deletar no produto e descartar. Nenhuma linha sai do banco, e a
# cascata desce pela arvore de dono do marmiteiro.
#
# Os testes contam linhas com SQL cru de proposito: `SellerProfile.count` passa
# pelo Active Record e nao provaria nada sobre o que sobrou no banco.
class DiscardCascadeTest < ActiveSupport::TestCase
  # Arvore descartavel + a tabela que fica de fora da cascata.
  TABELAS = %w[seller_profiles dishes weekly_menus selling_locations reviews weekly_menu_dishes].freeze

  setup do
    @marli = seller_profiles(:marli_marmitas)
  end

  def linhas(tabela)
    ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{tabela}")
  end

  def contagem_das_tabelas
    TABELAS.index_with { |tabela| linhas(tabela) }
  end

  test "descartar o marmiteiro nao apaga nenhuma linha do banco" do
    antes = contagem_das_tabelas

    @marli.discard

    assert_equal antes, contagem_das_tabelas
  end

  test "descartar o marmiteiro desce para pratos, cardapios, pontos e avaliacoes" do
    @marli.discard

    assert_predicate @marli, :discarded?
    # `count` em vez de `assert_empty`: minitest 6 estoura ArgumentError ao
    # montar a mensagem de uma ActiveRecord::Relation, e o teste falharia com um
    # erro que nao diz nada.
    assert_equal 0, @marli.dishes.kept.count
    assert_equal 0, @marli.weekly_menus.kept.count
    assert_equal 0, @marli.selling_locations.kept.count
    assert_equal 0, @marli.reviews.kept.count

    assert_equal 2, @marli.dishes.discarded.count
    assert_equal 2, @marli.weekly_menus.discarded.count
    assert_equal 2, @marli.selling_locations.discarded.count
    assert_equal 2, @marli.reviews.discarded.count
  end

  test "a cascata para no marmiteiro descartado e nao encosta em quem nao e dele" do
    @marli.discard

    assert_predicate seller_profiles(:jorge_quentinhas), :kept?
    assert_predicate dishes(:carne_de_panela), :kept?
    assert_predicate weekly_menus(:jorge_semana_atual), :kept?
    assert_predicate selling_locations(:rua_do_catete), :kept?
  end

  # Este e o motivo da issue: `weekly_menu_dishes` guarda quanto foi anunciado e
  # quanto sobrou naquele dia. Descartar prato ou marmiteiro nao pode tocar nele.
  test "a baixa do dia sobrevive ao descarte do prato e do marmiteiro" do
    baixa = weekly_menu_dishes(:marli_feijoada_semana_passada)

    dishes(:feijoada).discard
    @marli.discard

    baixa.reload

    assert_equal 25, baixa.available_quantity
    assert_equal 0, baixa.remaining_quantity
    assert_equal 3, WeeklyMenuDish.joins(:dish).where(dishes: { seller_profile: @marli }).count
  end

  test "undiscard devolve exatamente o que caiu na cascata" do
    @marli.discard
    @marli.undiscard

    assert_predicate @marli, :kept?
    assert_equal 2, @marli.dishes.kept.count
    assert_equal 2, @marli.weekly_menus.kept.count
    assert_equal 2, @marli.selling_locations.kept.count
    assert_equal 2, @marli.reviews.kept.count
  end

  # Se o `undiscard` desfizesse tudo o que esta descartado, um prato que a
  # propria marmiteira tirou do ar semanas atras voltaria sozinho.
  test "undiscard nao ressuscita o que o marmiteiro tinha descartado antes" do
    frango = dishes(:frango_grelhado)
    frango.discard

    @marli.discard
    @marli.undiscard

    assert_predicate frango.reload, :discarded?
    assert_predicate dishes(:feijoada).reload, :kept?
  end

  test "um cardapio descartado some dos escopos que a vitrine e o painel usam" do
    menu = weekly_menus(:marli_semana_atual)

    menu.discard

    assert_not_includes WeeklyMenu.active, menu
    assert_not_includes WeeklyMenu.available_now, menu
    assert_not_includes @marli.weekly_menus.kept, menu
    assert_not_includes WeeklyMenu.past, weekly_menus(:marli_semana_passada).tap(&:discard)
  end

  test "uma avaliacao descartada sai da lista publica e para de pesar na nota" do
    review = reviews(:carla_sobre_marli)

    review.discard

    assert_not_includes @marli.reviews.published, review
    assert_equal({ 4 => 1 }, Review.rating_distribution(@marli.id))
  end

  # `SellingLocation` limita o marmiteiro a tres pontos de venda. Um ponto
  # descartado nao pode continuar ocupando vaga.
  test "ponto de venda descartado libera vaga no limite de tres" do
    marli_locations = @marli.selling_locations
    marli_locations.create!(name: "Praca Sao Salvador 2", latitude: -22.9338, longitude: -43.1856)

    quarto = marli_locations.build(name: "Cobal do Humaita", latitude: -22.9556, longitude: -43.1934)

    assert_not_predicate quarto, :valid?

    marli_locations.kept.first.discard

    assert_predicate quarto, :valid?
  end
end
