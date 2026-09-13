require "test_helper"

# GET /api/v1/seller/dishes, .../favorites_stats, GET/POST/PATCH/DELETE
# .../dishes/:id
#
# O discard de prato (DELETE de um prato solto) ja esta coberto em
# discard_test.rb: aqui so o que falta.
class Api::V1::Seller::DishesTest < ActionDispatch::IntegrationTest
  setup do
    @marli = seller_profiles(:marli_marmitas)
    @headers = auth_headers(users(:marli))
    @feijoada = dishes(:feijoada)
    @frango = dishes(:frango_grelhado)
  end

  test "sem token e 401" do
    get "/api/v1/seller/dishes"

    assert_response :unauthorized
  end

  test "quem nao tem perfil de marmiteiro recebe 403" do
    get "/api/v1/seller/dishes", headers: auth_headers(users(:carla))

    assert_response :forbidden
    assert_equal "Seller profile required", json_response["error"]
  end

  test "index: dona ve os proprios pratos" do
    get "/api/v1/seller/dishes", headers: @headers

    assert_response :ok
    ids = json_response["dishes"].map { |d| d["id"] }
    assert_equal [ @feijoada.id, @frango.id ].sort, ids.sort
  end

  test "index: active_only=true filtra os inativos" do
    @frango.update!(active: false)

    get "/api/v1/seller/dishes", params: { active_only: "true" }, headers: @headers

    assert_response :ok
    ids = json_response["dishes"].map { |d| d["id"] }
    assert_includes ids, @feijoada.id
    assert_not_includes ids, @frango.id
  end

  test "index: quem nao tem prato recebe lista vazia" do
    get "/api/v1/seller/dishes", headers: auth_headers(users(:bia))

    assert_response :ok
    assert_empty json_response["dishes"]
  end

  test "favorites_stats: percentual de favoritos por prato" do
    get "/api/v1/seller/dishes/favorites_stats", headers: @headers

    assert_response :ok
    # feijoada: favorites_count 1; frango: 0 (default da coluna).
    assert_equal 1, json_response["total_favorites"]
    top = json_response["top_dishes"]
    feijoada_stats = top.find { |d| d["id"] == @feijoada.id }
    frango_stats = top.find { |d| d["id"] == @frango.id }
    assert_equal 100.0, feijoada_stats["percentage"]
    assert_equal 0, frango_stats["percentage"]
  end

  test "favorites_stats: sem prato nao explode em divisao por zero" do
    get "/api/v1/seller/dishes/favorites_stats", headers: auth_headers(users(:bia))

    assert_response :ok
    assert_equal 0, json_response["total_favorites"]
    assert_empty json_response["top_dishes"]
  end

  test "show: dona ve o proprio prato" do
    get "/api/v1/seller/dishes/#{@feijoada.id}", headers: @headers

    assert_response :ok
    assert_equal "Feijoada completa", json_response.dig("dish", "name")
  end

  test "show: prato de outro marmiteiro e 404" do
    outro = dishes(:carne_de_panela)

    get "/api/v1/seller/dishes/#{outro.id}", headers: @headers

    assert_response :not_found
    assert_equal "Dish not found", json_response["error"]
  end

  test "show: prato inexistente e 404" do
    get "/api/v1/seller/dishes/#{Dish.maximum(:id).to_i + 1000}", headers: @headers

    assert_response :not_found
  end

  test "create: prato valido" do
    assert_difference -> { @marli.dishes.count }, 1 do
      post "/api/v1/seller/dishes",
           params: { dish: { name: "Bife acebolado", base_price: 24.0 } },
           headers: @headers
    end

    assert_response :created
    assert_equal "Dish created successfully", json_response["message"]
    assert_equal "Bife acebolado", json_response.dig("dish", "name")
  end

  test "create: sem name e 422" do
    assert_no_difference -> { @marli.dishes.count } do
      post "/api/v1/seller/dishes", params: { dish: { base_price: 10.0 } }, headers: @headers
    end

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Name can't be blank"
  end

  test "create: base_price zero ou negativo e 422" do
    assert_no_difference -> { @marli.dishes.count } do
      post "/api/v1/seller/dishes", params: { dish: { name: "Prato X", base_price: 0 } }, headers: @headers
    end

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Base price must be greater than 0"
  end

  test "update: dona atualiza o proprio prato" do
    patch "/api/v1/seller/dishes/#{@feijoada.id}", params: { dish: { base_price: 30.0 } }, headers: @headers

    assert_response :ok
    assert_equal "Dish updated successfully", json_response["message"]
    assert_equal 30.0, json_response.dig("dish", "base_price")
    assert_equal 30.0, @feijoada.reload.base_price.to_f
  end

  test "update: prato de outro marmiteiro e 404" do
    outro = dishes(:carne_de_panela)

    patch "/api/v1/seller/dishes/#{outro.id}", params: { dish: { base_price: 5.0 } }, headers: @headers

    assert_response :not_found
    assert_equal 20.00, outro.reload.base_price.to_f
  end

  # Este caso NAO esta em discard_test.rb, que so testa um prato solto.
  test "destroy: nao deixa apagar prato que esta em cardapio ativo" do
    assert @feijoada.weekly_menus.active.available_now.any?

    delete "/api/v1/seller/dishes/#{@feijoada.id}", headers: @headers

    assert_response :unprocessable_entity
    assert_equal "Cannot delete dish that is in active menus", json_response["error"]
    assert_not @feijoada.reload.discarded?
  end
end
