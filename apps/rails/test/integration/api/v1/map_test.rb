require "test_helper"

class Api::V1::MapTest < ActionDispatch::IntegrationTest
  CATETE = { latitude: -22.929500, longitude: -43.177400, radius: 5 }.freeze

  def sellers_no_mapa(headers: {})
    get "/api/v1/map/sellers", params: CATETE, headers: headers
    assert_response :ok
    response.parsed_body["features"]
  end

  def nomes(features)
    features.map { |f| f.dig("properties", "business_name") }
  end

  test "o mapa mostra o ponto fixo e o ambulante" do
    nomes_no_mapa = nomes(sellers_no_mapa(headers: auth_headers(users(:carla))))

    assert_includes nomes_no_mapa, seller_profiles(:marli_marmitas).business_name
    assert_includes nomes_no_mapa, seller_profiles(:neide_ambulante).business_name
  end

  # A segunda ponta da correcao: o job pode estar atrasado ou parado, e mesmo
  # assim o anuncio vencido nao aparece. Nenhum job roda neste teste.
  test "anuncio vencido nao aparece no mapa mesmo sem o job ter rodado" do
    tiao = seller_profiles(:tiao_vencido)
    assert tiao.currently_active, "no banco ele continua ligado: e o job que nao rodou"

    assert_not_includes nomes(sellers_no_mapa(headers: auth_headers(users(:carla)))),
                        tiao.business_name
  end

  test "quando o prazo vence o marmiteiro some do mapa, sem ninguem desligar nada" do
    marli = seller_profiles(:marli_marmitas)
    assert_includes nomes(sellers_no_mapa(headers: auth_headers(users(:carla)))), marli.business_name

    travel_to marli.leaving_at + 1.minute do
      assert_not_includes nomes(sellers_no_mapa(headers: auth_headers(users(:carla)))),
                          marli.business_name
    end

    assert marli.reload.currently_active, "a linha do banco nao mudou: quem filtrou foi a leitura"
  end

  test "o GeoJSON diz de que tipo e o pino e de quando e a posicao" do
    features = sellers_no_mapa(headers: auth_headers(users(:carla)))

    marli = features.find { |f| f.dig("properties", "business_name") == "Marmitas da Dona Marli" }
    neide = features.find { |f| f.dig("properties", "business_name") == "Marmita da Neide" }

    assert_equal "ponto", marli.dig("properties", "kind")
    assert_nil marli.dig("properties", "position_updated_at")

    assert_equal "circulando", neide.dig("properties", "kind")
    assert_not_nil neide.dig("properties", "position_updated_at")
  end

  # A BRES-113 ainda nao decidiu o que um visitante sem token pode ver. Ate la a
  # coordenada exata de uma pessoa na rua nao sai em resposta publica.
  test "sem token o mapa nao entrega a posicao ao vivo do ambulante" do
    nomes_no_mapa = nomes(sellers_no_mapa)

    assert_includes nomes_no_mapa, seller_profiles(:marli_marmitas).business_name
    assert_not_includes nomes_no_mapa, seller_profiles(:neide_ambulante).business_name
  end

  test "sem token o perfil publico tambem nao entrega a posicao ao vivo" do
    get "/api/v1/sellers/#{seller_profiles(:neide_ambulante).id}"

    assert_response :ok
    seller = response.parsed_body["seller"]
    assert_nil seller["current_location"]
    assert_empty seller["selling_locations"]
  end

  test "map/bounds tambem filtra o anuncio vencido" do
    get "/api/v1/map/bounds",
        params: { ne_lat: -22.85, ne_lng: -43.10, sw_lat: -23.00, sw_lng: -43.30 },
        headers: auth_headers(users(:carla))

    assert_response :ok
    nomes_no_mapa = nomes(response.parsed_body["features"])

    assert_includes nomes_no_mapa, seller_profiles(:marli_marmitas).business_name
    assert_not_includes nomes_no_mapa, seller_profiles(:tiao_vencido).business_name
  end

  test "sellers/nearby nao devolve quem venceu" do
    get "/api/v1/sellers/nearby", params: CATETE, headers: auth_headers(users(:carla))

    assert_response :ok
    nomes_encontrados = response.parsed_body["sellers"].map { |s| s["business_name"] }

    assert_includes nomes_encontrados, seller_profiles(:marli_marmitas).business_name
    assert_not_includes nomes_encontrados, seller_profiles(:tiao_vencido).business_name
  end

  # BRES-129: `verified` era portao das quatro rotas de descoberta, e nada no
  # sistema grava `verified = true`. Um marmiteiro novo nao aparecia nunca.
  # `paulo_novo` esta ativo e nunca foi verificado.
  test "marmiteiro ativo e nao verificado aparece no mapa" do
    nomes_no_mapa = nomes(sellers_no_mapa(headers: auth_headers(users(:carla))))

    assert_includes nomes_no_mapa, seller_profiles(:paulo_novo).business_name
  end

  test "map/bounds tambem mostra o nao verificado" do
    get "/api/v1/map/bounds",
        params: { ne_lat: -22.85, ne_lng: -43.10, sw_lat: -23.00, sw_lng: -43.30 },
        headers: auth_headers(users(:carla))

    assert_response :ok
    nomes_no_mapa = nomes(response.parsed_body["features"])

    assert_includes nomes_no_mapa, seller_profiles(:paulo_novo).business_name
  end

  test "a ordenacao por distancia do mapa nao depende de verified" do
    features = sellers_no_mapa(headers: auth_headers(users(:carla)))
    distancias = features.map { |f| f.dig("properties", "distance_km") }.compact

    assert_equal distancias.sort, distancias, "as distancias tem que vir crescentes"
  end
end
