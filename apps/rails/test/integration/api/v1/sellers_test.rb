require "test_helper"

# BRES-129: `verified` era portao, nao selo. As quatro rotas de descoberta
# filtravam por `.verified`, e nada no sistema grava `verified = true` — todo
# marmiteiro novo ficava invisivel para sempre. Este arquivo cobre as duas
# rotas de `SellersController` (`GET /api/v1/sellers` e `/nearby`); o mapa esta
# em `map_test.rb`.
class Api::V1::SellersTest < ActionDispatch::IntegrationTest
  CATETE = { latitude: -22.929500, longitude: -43.177400, radius: 5 }.freeze

  test "GET /api/v1/sellers mostra marmiteiro ativo e nunca verificado" do
    get "/api/v1/sellers"

    assert_response :ok
    nomes = json_response["sellers"].map { |s| s["business_name"] }

    assert_includes nomes, seller_profiles(:paulo_novo).business_name
  end

  test "GET /api/v1/sellers/nearby mostra o nao verificado e mantem a ordem por distancia" do
    get "/api/v1/sellers/nearby", params: CATETE

    assert_response :ok
    sellers = json_response["sellers"]
    nomes = sellers.map { |s| s["business_name"] }

    assert_includes nomes, seller_profiles(:paulo_novo).business_name

    marli_idx = nomes.index(seller_profiles(:marli_marmitas).business_name)
    paulo_idx = nomes.index(seller_profiles(:paulo_novo).business_name)

    assert marli_idx < paulo_idx, "a Marli (mais perto) tem que vir antes do Paulo (mais longe), sem ligacao com `verified`"
  end

  test "GET /api/v1/sellers/nearby nao mostra quem nao esta anunciando" do
    get "/api/v1/sellers/nearby", params: CATETE

    assert_response :ok
    nomes = json_response["sellers"].map { |s| s["business_name"] }

    assert_not_includes nomes, seller_profiles(:jorge_quentinhas).business_name
  end
end
