require "test_helper"

# BRES-141: `includes(weekly_menu_dishes: { dish: :photos })` estourava
# `AssociationNotFoundError` porque `Dish` usa `has_many_attached :photos`, que
# cria `photos_attachments`/`photos_blobs`, nao uma associacao `photos`. Isso
# derrubava a vitrine de cardapios para todo mundo, com ou sem token.
class Api::V1::MenusTest < ActionDispatch::IntegrationTest
  test "GET /api/v1/menus sem token lista os cardapios disponiveis agora" do
    get "/api/v1/menus"

    assert_response :ok
    titulos = json_response["menus"].map { |m| m["title"] }

    assert_includes titulos, weekly_menus(:marli_semana_atual).title
    assert_not_includes titulos, weekly_menus(:marli_semana_passada).title
  end

  test "GET /api/v1/menus com token tambem funciona, mesmo com prato sem foto anexada" do
    get "/api/v1/menus", headers: auth_headers(users(:carla))

    assert_response :ok
    menu = json_response["menus"].find { |m| m["id"] == weekly_menus(:marli_semana_atual).id }
    prato = menu["preview_dishes"].find { |d| d["id"] == dishes(:feijoada).id }

    assert_equal weekly_menu_dishes(:marli_feijoada).remaining_quantity, prato["remaining_quantity"]
    refute_nil menu["seller"]["business_name"]
  end

  test "GET /api/v1/menus/:id sem token mostra as fotos do prato" do
    dishes(:frango_grelhado).photos.attach(
      io: StringIO.new("fake"), filename: "frango.jpg", content_type: "image/jpeg"
    )

    get "/api/v1/menus/#{weekly_menus(:marli_semana_atual).id}"

    assert_response :ok
    prato = json_response.dig("menu", "dishes").find { |d| d["dish_id"] == dishes(:frango_grelhado).id }

    assert_equal 1, prato["photos"].size
  end

  test "GET /api/v1/menus/available_today sem token nao estoura" do
    get "/api/v1/menus/available_today"

    assert_response :ok
    titulos = json_response["menus"].map { |m| m["title"] }
    assert_includes titulos, weekly_menus(:marli_semana_atual).title
  end

  test "GET /api/v1/menus/available_today com token nao estoura" do
    get "/api/v1/menus/available_today", headers: auth_headers(users(:carla))

    assert_response :ok
    titulos = json_response["menus"].map { |m| m["title"] }
    assert_includes titulos, weekly_menus(:marli_semana_atual).title
  end
end
