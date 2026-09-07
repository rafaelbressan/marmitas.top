require "test_helper"

# PATCH /api/v1/seller/weekly_menus/:id/dishes/:dish_id/quantity
class Api::V1::Seller::WeeklyMenuDishesTest < ActionDispatch::IntegrationTest
  setup do
    @menu = weekly_menus(:marli_semana_atual)
    @feijoada = weekly_menu_dishes(:marli_feijoada) # 20 disponiveis, 8 restantes
    @url = "/api/v1/seller/weekly_menus/#{@menu.id}/dishes/#{@feijoada.dish_id}/quantity"
  end

  test "sold baixa a quantidade" do
    patch @url, params: { sold: 3 }, headers: auth_headers(users(:marli))

    assert_response :ok
    assert_equal 5, response.parsed_body.dig("dish", "remaining_quantity")
    assert_equal 5, @feijoada.reload.remaining_quantity
  end

  test "remaining_quantity ajusta para um numero absoluto" do
    patch @url, params: { remaining_quantity: 5 }, headers: auth_headers(users(:marli))

    assert_response :ok
    assert_equal 5, @feijoada.reload.remaining_quantity
  end

  # "Acabou" e uma frase distinta de "faltam 5", e o resultado tem que ser
  # inequivoco: zero restante e o prato fora da lista de disponiveis.
  test "remaining_quantity zero e acabou" do
    patch @url, params: { remaining_quantity: 0 }, headers: auth_headers(users(:marli))

    assert_response :ok
    assert_equal 0, @feijoada.reload.remaining_quantity
    assert_not @feijoada.available?
    assert_not_includes @menu.weekly_menu_dishes.available, @feijoada
  end

  test "mandar sold e remaining_quantity juntos e erro: o servidor nao adivinha" do
    patch @url, params: { sold: 3, remaining_quantity: 5 }, headers: auth_headers(users(:marli))

    assert_response :unprocessable_entity
    assert_equal 8, @feijoada.reload.remaining_quantity
  end

  test "nao mandar nenhum dos dois e erro" do
    patch @url, params: {}, headers: auth_headers(users(:marli))

    assert_response :unprocessable_entity
    assert_equal 8, @feijoada.reload.remaining_quantity
  end

  test "baixa maior que o estoque e recusada e nao deixa negativo" do
    patch @url, params: { sold: 9 }, headers: auth_headers(users(:marli))

    assert_response :unprocessable_entity
    assert_equal 8, response.parsed_body["remaining_quantity"]
    assert_equal 8, @feijoada.reload.remaining_quantity
  end

  test "sold zero ou negativo e recusado" do
    [ 0, -3 ].each do |amount|
      patch @url, params: { sold: amount }, headers: auth_headers(users(:marli))

      assert_response :unprocessable_entity
      assert_equal 8, @feijoada.reload.remaining_quantity
    end
  end

  test "nao da para pedir mais restante do que o total disponivel" do
    patch @url, params: { remaining_quantity: 999 }, headers: auth_headers(users(:marli))

    assert_response :unprocessable_entity
    assert_equal 8, @feijoada.reload.remaining_quantity
  end

  test "sem token nao baixa nada" do
    patch @url, params: { sold: 3 }

    assert_response :unauthorized
    assert_equal 8, @feijoada.reload.remaining_quantity
  end

  test "o token de outro marmiteiro nao baixa o cardapio da Marli" do
    patch @url, params: { sold: 3 }, headers: auth_headers(users(:jorge))

    assert_response :not_found
    assert_equal 8, @feijoada.reload.remaining_quantity
  end

  test "prato que nao esta no cardapio da 404" do
    outro = dishes(:carne_de_panela)

    patch "/api/v1/seller/weekly_menus/#{@menu.id}/dishes/#{outro.id}/quantity",
          params: { sold: 1 }, headers: auth_headers(users(:marli))

    assert_response :not_found
  end
end
