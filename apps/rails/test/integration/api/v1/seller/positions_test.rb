require "test_helper"

# PUT /api/v1/seller/position — a posicao ao vivo do ambulante.
class Api::V1::Seller::PositionsTest < ActionDispatch::IntegrationTest
  # Um quarteirao adiante de onde a Neide estava.
  NOVA_POSICAO = { latitude: -22.925800, longitude: -43.179100 }.freeze

  test "o ambulante com turno aberto regrava a posicao na propria linha circulando" do
    neide = seller_profiles(:neide_ambulante)
    linha = selling_locations(:neide_circulando)

    put "/api/v1/seller/position", params: NOVA_POSICAO, headers: auth_headers(users(:neide))

    assert_response :ok
    corpo = response.parsed_body
    assert_equal "circulando", corpo.dig("position", "kind")
    assert_in_delta NOVA_POSICAO[:latitude], corpo.dig("position", "latitude"), 0.000001

    linha.reload
    assert_in_delta NOVA_POSICAO[:latitude], linha.latitude.to_f, 0.000001
    assert_in_delta NOVA_POSICAO[:longitude], linha.longitude.to_f, 0.000001
    assert_not_nil linha.position_updated_at
    assert_equal neide.reload.current_location_id, linha.id
  end

  test "a coluna geography acompanha a posicao nova, senao o ambulante some do ST_DWithin" do
    put "/api/v1/seller/position", params: NOVA_POSICAO, headers: auth_headers(users(:neide))
    assert_response :ok

    encontrados = SellerProfile.nearby(NOVA_POSICAO[:latitude], NOVA_POSICAO[:longitude], 1)

    assert_includes encontrados, seller_profiles(:neide_ambulante)
    assert_in_delta 0.0, encontrados.first.distance_km.to_f, 0.05
  end

  test "sem token nao grava nada" do
    linha = selling_locations(:neide_circulando)
    antes = linha.latitude

    put "/api/v1/seller/position", params: NOVA_POSICAO

    assert_response :unauthorized
    assert_equal antes, linha.reload.latitude
  end

  test "o token de outro marmiteiro nao move o pino da Neide" do
    linha = selling_locations(:neide_circulando)
    antes = linha.latitude

    put "/api/v1/seller/position", params: NOVA_POSICAO, headers: auth_headers(users(:marli))

    # A Marli esta anunciando de um ponto fixo: a chamada nao move nem o pino
    # dela nem o de ninguem.
    assert_response :unprocessable_entity
    assert_equal antes, linha.reload.latitude
  end

  # A trava de privacidade e do servidor, nao do app: sem turno aberto nao ha
  # coordenada gravada.
  test "sem turno aberto a posicao e recusada" do
    jorge = users(:jorge)
    assert_not seller_profiles(:jorge_quentinhas).currently_active

    put "/api/v1/seller/position", params: NOVA_POSICAO, headers: auth_headers(jorge)

    assert_response :unprocessable_entity
    assert_match(/turno/i, response.parsed_body["error"])
    assert_nil seller_profiles(:jorge_quentinhas).reload.roaming_location
  end

  test "turno vencido conta como turno fechado" do
    neide = seller_profiles(:neide_ambulante)
    linha = selling_locations(:neide_circulando)
    antes = linha.latitude

    travel_to neide.leaving_at + 1.minute do
      put "/api/v1/seller/position", params: NOVA_POSICAO, headers: auth_headers(users(:neide))
    end

    assert_response :unprocessable_entity
    assert_equal antes, linha.reload.latitude
  end

  test "o pino de um ponto fixo nao anda" do
    marli = seller_profiles(:marli_marmitas)
    ponto = selling_locations(:largo_do_machado)
    assert marli.broadcasting?

    put "/api/v1/seller/position", params: NOVA_POSICAO, headers: auth_headers(users(:marli))

    assert_response :unprocessable_entity
    assert_match(/ponto fixo/i, response.parsed_body["error"])
    assert_equal ponto.latitude, ponto.reload.latitude
    assert_nil marli.reload.roaming_location
  end

  test "coordenada ausente e erro, nao vira (0, 0)" do
    linha = selling_locations(:neide_circulando)

    put "/api/v1/seller/position", params: { latitude: NOVA_POSICAO[:latitude] },
        headers: auth_headers(users(:neide))

    assert_response :bad_request
    assert_equal(-22.927, linha.reload.latitude.to_f)
  end

  test "coordenada fora de faixa e recusada" do
    put "/api/v1/seller/position", params: { latitude: 100.0, longitude: -43.1 },
        headers: auth_headers(users(:neide))

    assert_response :unprocessable_entity
  end

  test "GET position cria a linha circulando sob demanda e ela nao entra no limite de 3 pontos" do
    jorge = seller_profiles(:jorge_quentinhas)
    # Enche os 3 pontos salvos do Jorge.
    2.times do |i|
      jorge.selling_locations.create!(name: "Ponto #{i}", latitude: -22.9, longitude: -43.2)
    end
    assert_equal 3, jorge.selling_locations.pontos.count

    get "/api/v1/seller/position", headers: auth_headers(users(:jorge))

    assert_response :ok
    assert_equal "circulando", response.parsed_body.dig("position", "kind")
    assert_equal 3, jorge.reload.selling_locations.pontos.count
    assert_equal 1, jorge.selling_locations.roaming.count
  end

  test "GET position e idempotente: nunca cria uma segunda linha circulando" do
    2.times { get "/api/v1/seller/position", headers: auth_headers(users(:jorge)) }

    assert_response :ok
    assert_equal 1, seller_profiles(:jorge_quentinhas).selling_locations.roaming.count
  end

  test "a linha circulando fica fora da lista de pontos salvos" do
    get "/api/v1/seller/selling_locations", headers: auth_headers(users(:neide))

    assert_response :ok
    assert_empty response.parsed_body["locations"]
  end
end
