require "test_helper"

# GET /api/v1/menus, /:id, /available_today, /sellers/:id/menus — os cardapios
# que o app mostra antes do login (WeeklyMenuPolicy: tudo publico).
class Api::V1::MenusTest < ActionDispatch::IntegrationTest
  test "index lista os cardapios disponiveis agora" do
    get "/api/v1/menus", headers: auth_headers(users(:carla))

    assert_response :ok
    ids = json_response["menus"].map { |m| m["id"] }
    assert_includes ids, weekly_menus(:marli_semana_atual).id
  end

  test "show devolve o detalhe do cardapio" do
    menu = weekly_menus(:marli_semana_atual)

    get "/api/v1/menus/#{menu.id}"

    assert_response :ok
    corpo = json_response["menu"]

    assert_equal menu.id, corpo["id"]
    assert_equal menu.title, corpo["title"]
    assert corpo["is_available"]
    assert_equal seller_profiles(:marli_marmitas).business_name, corpo.dig("seller", "business_name")
  end

  test "show de cardapio inexistente e 404" do
    get "/api/v1/menus/0"

    assert_response :not_found
    assert_equal "Menu not found", json_response["error"]
  end

  test "available_today lista os cardapios que estao no ar" do
    get "/api/v1/menus/available_today", headers: auth_headers(users(:carla))

    assert_response :ok
    ids = json_response["menus"].map { |m| m["id"] }

    assert_includes ids, weekly_menus(:marli_semana_atual).id
    assert_not_includes ids, weekly_menus(:marli_semana_passada).id
  end

  test "sellers/:id/menus lista os cardapios daquele marmiteiro" do
    marli = seller_profiles(:marli_marmitas)

    get "/api/v1/sellers/#{marli.id}/menus", headers: auth_headers(users(:carla))

    assert_response :ok
    ids = json_response["menus"].map { |m| m["id"] }

    assert_includes ids, weekly_menus(:marli_semana_atual).id
    assert_not_includes ids, weekly_menus(:marli_semana_passada).id
  end

  test "sellers/:id/menus de marmiteiro inexistente e 404, sem exigir token" do
    get "/api/v1/sellers/0/menus"

    assert_response :not_found
    assert_equal "Seller not found", json_response["error"]
  end
end
