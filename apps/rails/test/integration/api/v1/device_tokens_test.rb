require "test_helper"

# GET/POST/DELETE /api/v1/device_tokens — tudo autenticado (DeviceTokenPolicy).
class Api::V1::DeviceTokensTest < ActionDispatch::IntegrationTest
  setup do
    @diego = users(:diego)
    @headers = auth_headers(@diego)
  end

  test "index lista so os tokens da propria conta, ativos e inativos" do
    get "/api/v1/device_tokens", headers: @headers

    assert_response :ok

    ids = json_response["device_tokens"].map { |t| t["id"] }
    assert_includes ids, device_tokens(:diego_android).id
    assert_includes ids, device_tokens(:diego_android_antigo).id
    assert_not_includes ids, device_tokens(:carla_iphone).id
  end

  test "index sem token e 401" do
    get "/api/v1/device_tokens"

    assert_response :unauthorized
  end

  test "create registra um token novo" do
    assert_difference -> { @diego.device_tokens.count }, 1 do
      post "/api/v1/device_tokens",
           params: { device_token: { token: "ExponentPushToken[diego-novo]", platform: "ios", device_name: "iPad do Diego" } },
           headers: @headers
    end

    assert_response :created
    assert_equal "Device token registered successfully", json_response["message"]
    assert_equal "ios", json_response.dig("device_token", "platform")
  end

  test "create sem token de autenticacao e 401" do
    post "/api/v1/device_tokens",
         params: { device_token: { token: "x", platform: "ios", device_name: "y" } }

    assert_response :unauthorized
  end

  # Mesmo par (token, platform) de um registro existente: o controller acha por
  # `find_or_initialize_by` e atualiza no lugar, em vez de criar outra linha.
  test "create com token e platform ja existentes atualiza em vez de duplicar" do
    existente = device_tokens(:diego_android)

    assert_no_difference -> { @diego.device_tokens.count } do
      post "/api/v1/device_tokens",
           params: { device_token: { token: existente.token, platform: existente.platform, device_name: "Novo nome do aparelho" } },
           headers: @headers
    end

    assert_response :ok
    assert_equal existente.id, json_response.dig("device_token", "id")
    assert_equal "Novo nome do aparelho", json_response.dig("device_token", "device_name")
    assert_equal "Novo nome do aparelho", existente.reload.device_name
  end

  test "create sem platform valida e 422" do
    post "/api/v1/device_tokens",
         params: { device_token: { token: "ExponentPushToken[qualquer]", platform: "windows_phone", device_name: "Aparelho" } },
         headers: @headers

    assert_response :unprocessable_entity
    assert_not_empty json_response["errors"]
  end

  test "destroy remove o token da propria conta" do
    token = device_tokens(:diego_android_antigo)

    delete "/api/v1/device_tokens/#{token.id}", headers: @headers

    assert_response :ok
    assert_equal "Device token removed successfully", json_response["message"]
    assert_not DeviceToken.exists?(token.id)
  end

  # `set_device_token` busca em `current_user.device_tokens.find`, entao o
  # token de outra conta nunca e encontrado.
  test "destroy do token de outra conta e 404" do
    token_da_carla = device_tokens(:carla_iphone)

    delete "/api/v1/device_tokens/#{token_da_carla.id}", headers: @headers

    assert_response :not_found
    assert_equal "Device token not found", json_response["error"]
    assert DeviceToken.exists?(token_da_carla.id)
  end

  test "destroy de id inexistente e 404" do
    delete "/api/v1/device_tokens/0", headers: @headers

    assert_response :not_found
    assert_equal "Device token not found", json_response["error"]
  end

  test "deactivate_all desativa todos os tokens ativos da propria conta" do
    assert @diego.device_tokens.active.exists?(id: device_tokens(:diego_android).id)

    post "/api/v1/device_tokens/deactivate_all", headers: @headers

    assert_response :ok
    assert_equal "All device tokens deactivated successfully", json_response["message"]
    assert_not @diego.device_tokens.active.exists?
    assert_not device_tokens(:diego_android).reload.active
  end
end
