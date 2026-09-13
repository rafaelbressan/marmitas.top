require "test_helper"

# GET/PATCH /api/v1/notification_preferences — so a propria conta
# (NotificationPreferencesPolicy). Mora em `users.notification_preferences`,
# jsonb com default no banco (db/structure.sql).
class Api::V1::NotificationPreferencesTest < ActionDispatch::IntegrationTest
  DEFAULTS = {
    "new_menus" => true,
    "promotions" => false,
    "order_updates" => true,
    "seller_arrivals" => true
  }.freeze

  setup do
    @carla = users(:carla)
    @headers = auth_headers(@carla)
  end

  test "show devolve o default de quem nunca mudou nada" do
    get "/api/v1/notification_preferences", headers: @headers

    assert_response :ok
    assert_equal DEFAULTS, json_response["notification_preferences"]
  end

  test "show sem token e 401" do
    get "/api/v1/notification_preferences"

    assert_response :unauthorized
  end

  test "update muda so as chaves enviadas e preserva o resto" do
    patch "/api/v1/notification_preferences",
          params: { notification_preferences: { promotions: true } },
          headers: @headers

    assert_response :ok
    esperado = DEFAULTS.merge("promotions" => true)
    assert_equal esperado, json_response["notification_preferences"]
    assert_equal esperado, @carla.reload.notification_preferences
  end

  test "update com duas chaves mescla as duas e mantem as outras" do
    patch "/api/v1/notification_preferences",
          params: { notification_preferences: { seller_arrivals: false, new_menus: false } },
          headers: @headers

    assert_response :ok
    esperado = DEFAULTS.merge("seller_arrivals" => false, "new_menus" => false)
    assert_equal esperado, json_response["notification_preferences"]
  end

  test "update sem token e 401" do
    patch "/api/v1/notification_preferences", params: { notification_preferences: { promotions: true } }

    assert_response :unauthorized
  end

  # `ActiveModel::Type::Boolean` so vira `false` para uma lista fechada de
  # valores (0, "false", "f" etc.); qualquer outra string vira `true`. Nao ha
  # validacao de boolean no model, entao isto nao da 422 — o valor so nasce
  # `true` de um jeito talvez inesperado por quem manda o parametro.
  test "update com valor que nao e boolean nem cai na lista de falsy vira true, sem 422" do
    patch "/api/v1/notification_preferences",
          params: { notification_preferences: { promotions: "lixo" } },
          headers: @headers

    assert_response :ok
    assert_equal true, json_response.dig("notification_preferences", "promotions")
  end
end
