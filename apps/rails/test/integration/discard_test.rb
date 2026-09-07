require "test_helper"

# Os `DELETE` da API descartam. Cada caso confere as duas coisas na mesma
# passada: a linha continua no banco, e o registro sumiu de quem o mostrava.
class DiscardTest < ActionDispatch::IntegrationTest
  test "apagar ponto de venda descarta e some do painel e da vitrine" do
    local = selling_locations(:praca_sao_salvador)
    antes = SellingLocation.count

    delete "/api/v1/seller/selling_locations/#{local.id}", headers: token_for(:marli)
    assert_response :success

    assert_equal antes, SellingLocation.count
    assert_predicate local.reload, :discarded?

    get "/api/v1/seller/selling_locations", headers: token_for(:marli)
    assert_not_includes ids(response.parsed_body["locations"]), local.id

    get "/api/v1/sellers/#{seller_profiles(:marli_marmitas).id}"
    assert_not_includes ids(response.parsed_body.dig("seller", "selling_locations")), local.id
  end

  test "apagar cardapio descarta e some da vitrine" do
    menu = weekly_menus(:marli_semana_passada)
    antes = WeeklyMenu.count

    delete "/api/v1/seller/weekly_menus/#{menu.id}", headers: token_for(:marli)
    assert_response :success

    assert_equal antes, WeeklyMenu.count
    assert_predicate menu.reload, :discarded?

    get "/api/v1/seller/weekly_menus", headers: token_for(:marli)
    assert_not_includes ids(response.parsed_body["menus"]), menu.id
  end

  test "apagar prato descarta, mas a baixa dele no cardapio passado fica" do
    prato = dishes(:feijoada)
    linha = weekly_menu_dishes(:marli_feijoada_semana_passada)
    # O controller recusa apagar prato que esta num cardapio no ar; este e o
    # unico caminho pelo qual o prato chega ao delete.
    weekly_menus(:marli_semana_atual).update!(active: false)
    antes = [ Dish.count, WeeklyMenuDish.count ]

    delete "/api/v1/seller/dishes/#{prato.id}", headers: token_for(:marli)
    assert_response :success

    assert_equal antes, [ Dish.count, WeeklyMenuDish.count ]
    assert_predicate prato.reload, :discarded?
    assert_predicate linha.reload, :kept?
    assert_equal 25, linha.available_quantity

    get "/api/v1/seller/dishes", headers: token_for(:marli)
    assert_not_includes ids(response.parsed_body["dishes"]), prato.id
  end

  test "tirar prato do cardapio descarta a linha em vez de apagar" do
    menu = weekly_menus(:marli_semana_atual)
    antes = WeeklyMenuDish.count

    delete "/api/v1/seller/weekly_menus/#{menu.id}/remove_dish/#{dishes(:feijoada).id}",
      headers: token_for(:marli)
    assert_response :success

    assert_equal antes, WeeklyMenuDish.count
    assert_predicate weekly_menu_dishes(:marli_feijoada).reload, :discarded?

    get "/api/v1/menus/#{menu.id}"
    assert_not_includes ids(response.parsed_body.dig("menu", "dishes")), weekly_menu_dishes(:marli_feijoada).id
  end

  test "apagar avaliacao descarta e some da lista do marmiteiro" do
    review = reviews(:carla_sobre_marli)
    antes = Review.count

    delete "/api/v1/reviews/#{review.id}", headers: token_for(:carla)
    assert_response :success

    assert_equal antes, Review.count
    assert_predicate review.reload, :discarded?

    get "/api/v1/sellers/#{seller_profiles(:marli_marmitas).id}/reviews"
    assert_not_includes ids(response.parsed_body["reviews"]), review.id
  end

  # O guarda de "prato em cardapio no ar" olha so a linha viva: tirar o prato
  # do cardapio destrava o delete, mesmo com a linha antiga ainda no banco.
  test "prato tirado do cardapio no ar pode ser apagado em seguida" do
    menu = weekly_menus(:marli_semana_atual)

    delete "/api/v1/seller/weekly_menus/#{menu.id}/remove_dish/#{dishes(:feijoada).id}",
      headers: token_for(:marli)
    assert_response :success

    delete "/api/v1/seller/dishes/#{dishes(:feijoada).id}", headers: token_for(:marli)
    assert_response :success
    assert_predicate dishes(:feijoada).reload, :discarded?
  end

  test "prato que ainda esta num cardapio no ar nao e apagado" do
    delete "/api/v1/seller/dishes/#{dishes(:feijoada).id}", headers: token_for(:marli)

    assert_response :unprocessable_entity
    assert_predicate dishes(:feijoada).reload, :kept?
  end

  test "registro descartado responde 404, nao 500" do
    dishes(:feijoada).discard

    get "/api/v1/seller/dishes/#{dishes(:feijoada).id}", headers: token_for(:marli)
    assert_response :not_found
  end

  test "marmiteiro descartado some da busca por perto e do proprio show" do
    seller_profiles(:marli_marmitas).discard

    get "/api/v1/sellers/nearby", params: { latitude: -22.9295, longitude: -43.1774, radius: 5 }
    assert_response :success
    assert_not_includes ids(response.parsed_body["sellers"]), seller_profiles(:marli_marmitas).id

    get "/api/v1/sellers/#{seller_profiles(:marli_marmitas).id}"
    assert_response :not_found
  end

  private
    def ids(colecao)
      Array(colecao).map { |item| item["id"] }
    end

    def token_for(fixture)
      token, = Warden::JWTAuth::UserEncoder.new.call(users(fixture), :user, nil)
      { "Authorization" => "Bearer #{token}" }
    end
end
