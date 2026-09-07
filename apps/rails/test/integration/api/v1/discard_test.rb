require "test_helper"

# BRES-140, criterio de aceite: descartar um marmiteiro pela API mantem as linhas
# dos pratos, cardapios, pontos e avaliacoes no banco — e tira todas elas da API.
class Api::V1::DiscardTest < ActionDispatch::IntegrationTest
  setup do
    @marli = seller_profiles(:marli_marmitas)
    @headers = auth_headers(users(:marli))
  end

  def linhas(tabela, condicao)
    ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{tabela} WHERE #{condicao}")
  end

  def linhas_da_marli
    {
      "seller_profiles" => linhas("seller_profiles", "id = #{@marli.id}"),
      "dishes" => linhas("dishes", "seller_profile_id = #{@marli.id}"),
      "weekly_menus" => linhas("weekly_menus", "seller_profile_id = #{@marli.id}"),
      "selling_locations" => linhas("selling_locations", "seller_profile_id = #{@marli.id}"),
      "reviews" => linhas("reviews", "seller_profile_id = #{@marli.id}")
    }
  end

  test "DELETE do perfil nao apaga nada e some da API inteira" do
    antes = linhas_da_marli

    delete "/api/v1/seller/profile", headers: @headers

    assert_response :ok
    assert_equal antes, linhas_da_marli, "o descarte apagou linha do banco"

    # Vitrine: ficha, listagem, cardapios e mapa.
    get "/api/v1/sellers/#{@marli.id}"
    assert_response :not_found

    get "/api/v1/sellers"
    assert_not_includes json_response["sellers"].map { |s| s["id"] }, @marli.id

    get "/api/v1/sellers/nearby", params: { latitude: -22.9295, longitude: -43.1774, radius: 5 }
    assert_equal [], json_response["sellers"].to_a

    get "/api/v1/map/sellers", params: { latitude: -22.9295, longitude: -43.1774, radius: 5 }
    assert_equal [], json_response["features"].to_a

    # Painel: o proprio dono nao ve mais o perfil.
    get "/api/v1/seller/profile", headers: @headers
    assert_response :not_found

    get "/api/v1/seller/dashboard", headers: @headers
    assert_response :forbidden
  end

  test "as avaliacoes da marmiteira descartada somem da lista publica" do
    delete "/api/v1/seller/profile", headers: @headers

    assert_response :ok

    get "/api/v1/sellers/#{@marli.id}/reviews"

    assert_response :not_found
  end

  test "recriar o perfil traz a arvore inteira de volta" do
    delete "/api/v1/seller/profile", headers: @headers

    post "/api/v1/seller/profile",
         params: { seller_profile: { business_name: "Marmitas da Dona Marli" } },
         headers: @headers

    assert_response :ok
    assert_equal "Seller profile restored successfully", json_response["message"]

    get "/api/v1/sellers/#{@marli.id}"

    assert_response :ok
    assert_equal 2, json_response.dig("seller", "selling_locations").size
    assert_not_nil json_response.dig("seller", "current_menu")
    assert_equal 2, @marli.reload.dishes.kept.count
    assert_equal 2, @marli.weekly_menus.kept.count
    assert_equal 2, @marli.reviews.kept.count
  end

  test "DELETE de prato descarta e mantem a linha, com a baixa do dia intacta" do
    prato = @marli.dishes.create!(name: "Bife acebolado", base_price: 24.0)

    delete "/api/v1/seller/dishes/#{prato.id}", headers: @headers

    assert_response :ok
    assert_equal 1, linhas("dishes", "id = #{prato.id}")
    assert_predicate prato.reload, :discarded?

    get "/api/v1/seller/dishes", headers: @headers
    assert_not_includes json_response["dishes"].map { |d| d["id"] }, prato.id

    get "/api/v1/seller/dishes/#{prato.id}", headers: @headers
    assert_response :not_found

    # A baixa de todos os cardapios da Marli continua onde estava.
    assert_equal 3, WeeklyMenuDish.joins(:dish).where(dishes: { seller_profile: @marli }).count
  end

  test "DELETE de cardapio fechado descarta e mantem a linha" do
    menu = weekly_menus(:marli_semana_passada)

    delete "/api/v1/seller/weekly_menus/#{menu.id}", headers: @headers

    assert_response :ok
    assert_equal 1, linhas("weekly_menus", "id = #{menu.id}")
    assert_predicate menu.reload, :discarded?

    get "/api/v1/seller/weekly_menus", headers: @headers
    assert_not_includes json_response["menus"].map { |m| m["id"] }, menu.id
  end

  test "DELETE de ponto de venda que nao esta no ar descarta e mantem a linha" do
    ponto = selling_locations(:praca_sao_salvador)

    delete "/api/v1/seller/selling_locations/#{ponto.id}", headers: @headers

    assert_response :ok
    assert_equal 1, linhas("selling_locations", "id = #{ponto.id}")
    assert_predicate ponto.reload, :discarded?

    get "/api/v1/seller/selling_locations", headers: @headers
    assert_not_includes json_response["locations"].map { |l| l["id"] }, ponto.id
  end

  test "DELETE de avaliacao descarta, mantem a linha e tira ela da nota" do
    review = reviews(:carla_sobre_marli)

    delete "/api/v1/reviews/#{review.id}", headers: auth_headers(users(:carla))

    assert_response :ok
    assert_equal 1, linhas("reviews", "id = #{review.id}")
    assert_predicate review.reload, :discarded?

    get "/api/v1/reviews/#{review.id}", headers: auth_headers(users(:carla))
    assert_response :not_found

    get "/api/v1/sellers/#{@marli.id}/reviews"
    assert_equal [ reviews(:diego_sobre_marli).id ], json_response["reviews"].map { |r| r["id"] }

    # A avaliacao descartada tambem para de contar na distribuicao da nota.
    assert_equal({ 4 => 1 }, Review.rating_distribution(@marli.id))
  end

  test "a fila de moderacao nao mostra avaliacao descartada" do
    review = reviews(:diego_sobre_jorge_em_moderacao)
    review.discard

    get "/api/v1/admin/reviews", headers: auth_headers(users(:admin))

    assert_response :ok
    assert_not_includes json_response["reviews"].map { |r| r["id"] }, review.id
    assert_equal 0, json_response.dig("stats", "total_pending")
  end

  test "favorito de prato descartado some da lista de favoritos" do
    dishes(:feijoada).discard

    get "/api/v1/favorites", headers: auth_headers(users(:carla))

    assert_response :ok
    assert_not_includes json_response["dishes"].map { |d| d["id"] }, dishes(:feijoada).id
    assert_not_includes json_response["favorites"].map { |f| f["favoritable_id"] },
                        dishes(:feijoada).id
  end
end
