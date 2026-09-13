require "test_helper"

# BRES-136: `GET /api/v1/sellers/:id` respondia sem token e vazava telefone,
# whatsapp e a lista inteira de pontos salvos com coordenada exata — inclusive
# os pontos onde o marmiteiro nao esta agora.
class Api::V1::SellersTest < ActionDispatch::IntegrationTest
  test "sem token, o perfil nao entrega telefone nem whatsapp" do
    get "/api/v1/sellers/#{seller_profiles(:marli_marmitas).id}"

    assert_response :ok
    seller = response.parsed_body["seller"]
    assert_not seller.key?("phone")
    assert_not seller.key?("whatsapp")
  end

  test "com token, o perfil entrega telefone e whatsapp" do
    marli = seller_profiles(:marli_marmitas)
    get "/api/v1/sellers/#{marli.id}", headers: auth_headers(users(:carla))

    assert_response :ok
    seller = response.parsed_body["seller"]
    assert_equal marli.phone, seller["phone"]
    assert_equal marli.whatsapp, seller["whatsapp"]
  end

  test "sem token, o ponto atual sai sem endereco nem coordenada" do
    get "/api/v1/sellers/#{seller_profiles(:marli_marmitas).id}"

    assert_response :ok
    seller = response.parsed_body["seller"]

    assert_equal "Largo do Machado", seller.dig("current_location", "name")
    assert_not seller["current_location"].key?("address")
    assert_not seller["current_location"].key?("latitude")
    assert_not seller["current_location"].key?("longitude")

    assert_equal 1, seller["selling_locations"].length
    assert_not seller["selling_locations"].first.key?("latitude")
  end

  test "com token, o ponto atual sai com endereco e coordenada exata" do
    marli = seller_profiles(:marli_marmitas)
    get "/api/v1/sellers/#{marli.id}", headers: auth_headers(users(:carla))

    assert_response :ok
    seller = response.parsed_body["seller"]

    assert_equal marli.current_location.address, seller.dig("current_location", "address")
    assert_in_delta marli.current_location.latitude.to_f, seller.dig("current_location", "latitude"), 0.000001
    assert_in_delta marli.current_location.longitude.to_f, seller.dig("current_location", "longitude"), 0.000001
  end

  test "so o ponto atual aparece — os outros pontos salvos do dono ficam de fora" do
    marli = seller_profiles(:marli_marmitas)
    assert marli.selling_locations.kept.pontos.count > 1, "a fixture precisa ter mais de um ponto para este teste valer algo"

    get "/api/v1/sellers/#{marli.id}", headers: auth_headers(users(:carla))

    assert_response :ok
    seller = response.parsed_body["seller"]

    assert_equal 1, seller["selling_locations"].length
    assert_equal marli.current_location.name, seller["selling_locations"].first["name"]
  end

  test "turno fechado: nem o ponto atual aparece" do
    jorge = seller_profiles(:jorge_quentinhas)
    assert_not jorge.broadcasting?

    get "/api/v1/sellers/#{jorge.id}", headers: auth_headers(users(:carla))

    assert_response :ok
    seller = response.parsed_body["seller"]
    assert_nil seller["current_location"]
    assert_empty seller["selling_locations"]
  end

  test "anuncio vencido some do perfil publico mesmo sem o job ter rodado" do
    tiao = seller_profiles(:tiao_vencido)
    assert tiao.currently_active, "no banco ele continua ligado: e o job que nao rodou"

    get "/api/v1/sellers/#{tiao.id}", headers: auth_headers(users(:carla))

    assert_response :ok
    seller = response.parsed_body["seller"]
    assert_nil seller["current_location"]
    assert_empty seller["selling_locations"]
  end

  test "circulando nao entra em selling_locations, nem para quem tem token" do
    neide = seller_profiles(:neide_ambulante)
    get "/api/v1/sellers/#{neide.id}", headers: auth_headers(users(:carla))

    assert_response :ok
    seller = response.parsed_body["seller"]
    assert_equal "circulando", neide.current_location.kind
    assert_not_nil seller["current_location"]
    assert_empty seller["selling_locations"]
  end
end
