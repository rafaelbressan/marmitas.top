require "test_helper"

# GET /api/v1/sellers, /:id, /nearby — a vitrine publica do marmiteiro.
# index, show e nearby respondem sem token (SellerProfilePolicy).
class Api::V1::SellersTest < ActionDispatch::IntegrationTest
  CATETE = { latitude: -22.929500, longitude: -43.177400, radius: 5 }.freeze

  test "index sem token lista os marmiteiros verificados" do
    get "/api/v1/sellers"

    assert_response :ok
    nomes = json_response["sellers"].map { |s| s["business_name"] }

    assert_includes nomes, seller_profiles(:marli_marmitas).business_name
    assert_includes nomes, seller_profiles(:ana_verdinha).business_name
  end

  test "show devolve a ficha do marmiteiro verificado" do
    marli = seller_profiles(:marli_marmitas)

    get "/api/v1/sellers/#{marli.id}"

    assert_response :ok
    seller = json_response["seller"]

    assert_equal marli.id, seller["id"]
    assert_equal marli.business_name, seller["business_name"]
    assert_equal marli.city, seller["city"]
    assert_equal marli.average_rating.to_f, seller["average_rating"]
    # phone, whatsapp e as coordenadas de selling_locations sem token sao
    # BRES-136, ainda nao mergeada: fora do escopo deste teste.
  end

  test "show de id inexistente e 404" do
    get "/api/v1/sellers/0"

    assert_response :not_found
    assert_equal "Seller not found", json_response["error"]
  end

  test "nearby com lat/lng encontra quem esta perto e anunciando" do
    get "/api/v1/sellers/nearby", params: CATETE

    assert_response :ok
    nomes = json_response["sellers"].map { |s| s["business_name"] }

    assert_includes nomes, seller_profiles(:marli_marmitas).business_name
    assert_equal CATETE[:latitude], json_response.dig("search_params", "latitude")
    assert_equal CATETE[:longitude], json_response.dig("search_params", "longitude")
  end

  test "nearby sem lat/lng e 400" do
    get "/api/v1/sellers/nearby"

    assert_response :bad_request
    assert_equal "Latitude and longitude required", json_response["error"]
  end
end
