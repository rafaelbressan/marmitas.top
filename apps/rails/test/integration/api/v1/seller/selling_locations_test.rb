require "test_helper"

# GET/POST /api/v1/seller/selling_locations, GET/PATCH/DELETE .../:id,
# .../:id/arrive, .../:id/leave
#
# O DELETE de um ponto que nao esta no ar ja esta coberto em discard_test.rb;
# o limite de 3 pontos e o conceito de "circulando" estao em positions_test.rb.
# Aqui so o que falta: CRUD feliz/invalido, escopo de dono e arrive/leave.
class Api::V1::Seller::SellingLocationsTest < ActionDispatch::IntegrationTest
  setup do
    @marli = seller_profiles(:marli_marmitas)
    @headers = auth_headers(users(:marli))
    @largo = selling_locations(:largo_do_machado)
    @praca = selling_locations(:praca_sao_salvador)
  end

  test "sem token e 401" do
    get "/api/v1/seller/selling_locations"

    assert_response :unauthorized
  end

  test "quem nao tem perfil de marmiteiro recebe 403" do
    get "/api/v1/seller/selling_locations", headers: auth_headers(users(:carla))

    assert_response :forbidden
    assert_equal "Seller profile required", json_response["error"]
  end

  test "index: dona ve os proprios pontos, sem a linha circulando" do
    get "/api/v1/seller/selling_locations", headers: @headers

    assert_response :ok
    locais = json_response["locations"]
    assert_equal [ @largo.id, @praca.id ].sort, locais.map { |l| l["id"] }.sort
    assert_equal [ "ponto" ], locais.map { |l| l["kind"] }.uniq
  end

  test "show: dona ve o proprio ponto" do
    get "/api/v1/seller/selling_locations/#{@largo.id}", headers: @headers

    assert_response :ok
    assert_equal "Largo do Machado", json_response.dig("location", "name")
  end

  test "show: ponto de outro marmiteiro e 404" do
    outro = selling_locations(:rua_do_catete)

    get "/api/v1/seller/selling_locations/#{outro.id}", headers: @headers

    assert_response :not_found
    assert_equal "Location not found", json_response["error"]
  end

  test "create: ponto valido" do
    assert_difference -> { @marli.selling_locations.kept.pontos.count }, 1 do
      post "/api/v1/seller/selling_locations",
           params: { selling_location: { name: "Praia do Flamengo", latitude: -22.9328, longitude: -43.1737 } },
           headers: @headers
    end

    assert_response :created
    assert_equal "Selling location created successfully", json_response["message"]
    assert_equal "Praia do Flamengo", json_response.dig("location", "name")
    assert_equal "ponto", json_response.dig("location", "kind")
  end

  test "create: sem name e 422" do
    assert_no_difference -> { @marli.selling_locations.kept.pontos.count } do
      post "/api/v1/seller/selling_locations",
           params: { selling_location: { latitude: -22.93, longitude: -43.17 } },
           headers: @headers
    end

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Name can't be blank"
  end

  test "update: dona atualiza o proprio ponto" do
    patch "/api/v1/seller/selling_locations/#{@largo.id}",
          params: { selling_location: { notes: "Agora do outro lado da praca" } },
          headers: @headers

    assert_response :ok
    assert_equal "Agora do outro lado da praca", json_response.dig("location", "notes")
    assert_equal "Agora do outro lado da praca", @largo.reload.notes
  end

  test "arrive: chegada nova, sem conflito" do
    jorge_headers = auth_headers(users(:jorge))
    catete = selling_locations(:rua_do_catete)
    assert_not seller_profiles(:jorge_quentinhas).currently_active

    post "/api/v1/seller/selling_locations/#{catete.id}/arrive", headers: jorge_headers

    assert_response :ok
    assert_equal "Arrival announced successfully", json_response["message"]
    status = json_response["seller"]
    assert status["currently_active"]
    assert_equal catete.id, status.dig("current_location", "id")
    assert seller_profiles(:jorge_quentinhas).reload.currently_active
  end

  test "arrive: ja anunciando em outro ponto e 422" do
    assert @marli.currently_active
    assert_equal @largo.id, @marli.current_location_id

    post "/api/v1/seller/selling_locations/#{@praca.id}/arrive", headers: @headers

    assert_response :unprocessable_entity
    assert_equal "Already broadcasting from Largo do Machado. Please leave first.", json_response["error"]
    assert_equal @largo.id, @marli.reload.current_location_id
  end

  test "leave: sai do ponto onde esta" do
    assert @marli.currently_active

    post "/api/v1/seller/selling_locations/#{@largo.id}/leave", headers: @headers

    assert_response :ok
    assert_equal "Departure announced successfully", json_response["message"]
    status = json_response["seller"]
    assert_not status["currently_active"]
    assert_nil status["current_location"]
    assert_not @marli.reload.currently_active
  end

  test "leave: quem nao esta anunciando recebe 422" do
    jorge_location = selling_locations(:rua_do_catete)
    assert_not seller_profiles(:jorge_quentinhas).currently_active

    post "/api/v1/seller/selling_locations/#{jorge_location.id}/leave", headers: auth_headers(users(:jorge))

    assert_response :unprocessable_entity
    assert_equal "Not currently broadcasting", json_response["error"]
  end

  test "leave: sair de um ponto onde nao esta e 422" do
    assert @marli.currently_active
    assert_equal @largo.id, @marli.current_location_id

    post "/api/v1/seller/selling_locations/#{@praca.id}/leave", headers: @headers

    assert_response :unprocessable_entity
    assert_equal "Not at this location", json_response["error"]
    assert @marli.reload.currently_active
  end

  # Nao esta em discard_test.rb, que so testa o descarte de um ponto fora do ar.
  test "destroy: nao deixa apagar o ponto onde esta anunciando agora" do
    assert_equal @largo.id, @marli.current_location_id

    delete "/api/v1/seller/selling_locations/#{@largo.id}", headers: @headers

    assert_response :unprocessable_entity
    assert_equal "Cannot delete location while broadcasting from it. Please leave first.",
                 json_response["error"]
    assert_not @largo.reload.discarded?
  end
end
