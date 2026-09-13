require "test_helper"

# GET/POST/PATCH/DELETE /api/v1/seller/profile
#
# DELETE (descarte + restauracao) ja esta coberto em discard_test.rb: aqui so
# o que falta — show, create e update.
class Api::V1::Seller::ProfilesTest < ActionDispatch::IntegrationTest
  URL = "/api/v1/seller/profile".freeze

  setup do
    @marli = seller_profiles(:marli_marmitas)
    @headers = auth_headers(users(:marli))
  end

  test "show: dona ve o proprio perfil" do
    get URL, headers: @headers

    assert_response :ok
    # `show` devolve o perfil direto na raiz, sem envelope `{ profile: ... }`
    # (diferente de create/update).
    assert_equal @marli.id, json_response["id"]
    assert_equal "Marmitas da Dona Marli", json_response["business_name"]
    assert_equal "RJ", json_response["state"]
    assert json_response["currently_active"]
  end

  # ProfilesController NAO inclui SellerProfileScope (diferente dos outros tres
  # controllers do painel): show?/create? na policy sao `signed_in?`, de
  # proposito, porque e o caminho de cadastro de quem ainda nao tem perfil.
  # Por isso aqui a resposta e 404 "crie um primeiro", nao 403.
  test "show: quem ainda nao tem perfil recebe 404, nao 403" do
    get URL, headers: auth_headers(users(:carla))

    assert_response :not_found
    assert_equal "Seller profile not found. Create one first.", json_response["error"]
  end

  test "show: sem token e 401" do
    get URL

    assert_response :unauthorized
  end

  # Confirma empiricamente que create NAO fica preso atras de um perfil que
  # ainda nao existe: quem nunca teve perfil consegue criar o primeiro.
  test "create: quem nao tem perfil consegue criar o primeiro" do
    assert_nil users(:carla).seller_profile

    assert_difference -> { SellerProfile.count }, 1 do
      post URL, params: { seller_profile: { business_name: "Marmitas da Carla", city: "Rio de Janeiro", state: "RJ" } },
           headers: auth_headers(users(:carla))
    end

    assert_response :created
    assert_equal "Seller profile created successfully", json_response["message"]
    assert_equal "Marmitas da Carla", json_response.dig("profile", "business_name")
  end

  test "create: quem ja tem perfil recebe erro, nao duplica" do
    assert_no_difference -> { SellerProfile.count } do
      post URL, params: { seller_profile: { business_name: "Outro nome" } }, headers: @headers
    end

    assert_response :unprocessable_entity
    assert_equal "Seller profile already exists", json_response["error"]
  end

  test "create: sem business_name e 422" do
    assert_no_difference -> { SellerProfile.count } do
      post URL, params: { seller_profile: { city: "Rio de Janeiro" } }, headers: auth_headers(users(:diego))
    end

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Business name can't be blank"
  end

  test "update: dona atualiza o proprio perfil" do
    patch URL, params: { seller_profile: { business_name: "Marmitas da Dona Marli 2" } }, headers: @headers

    assert_response :ok
    assert_equal "Seller profile updated successfully", json_response["message"]
    assert_equal "Marmitas da Dona Marli 2", json_response.dig("profile", "business_name")
    assert_equal "Marmitas da Dona Marli 2", @marli.reload.business_name
  end

  test "update: business_name em branco e 422 e nao muda nada" do
    patch URL, params: { seller_profile: { business_name: "" } }, headers: @headers

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Business name can't be blank"
    assert_equal "Marmitas da Dona Marli", @marli.reload.business_name
  end

  test "update: sem token e 401" do
    patch URL, params: { seller_profile: { business_name: "X" } }

    assert_response :unauthorized
    assert_equal "Marmitas da Dona Marli", @marli.reload.business_name
  end
end
