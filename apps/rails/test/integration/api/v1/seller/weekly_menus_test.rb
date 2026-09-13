require "test_helper"

# GET/POST /api/v1/seller/weekly_menus, GET/PATCH/DELETE .../:id,
# .../:id/add_dish, .../:id/remove_dish/:dish_id, .../:id/duplicate,
# .../:id/whatsapp_text
#
# remove_dish (discard) e o DELETE de cardapio fechado ja estao cobertos em
# discard_test.rb: aqui so o que falta.
class Api::V1::Seller::WeeklyMenusTest < ActionDispatch::IntegrationTest
  setup do
    @marli = seller_profiles(:marli_marmitas)
    @headers = auth_headers(users(:marli))
    @atual = weekly_menus(:marli_semana_atual)
    @passado = weekly_menus(:marli_semana_passada)
  end

  test "sem token e 401" do
    get "/api/v1/seller/weekly_menus"

    assert_response :unauthorized
  end

  test "quem nao tem perfil de marmiteiro recebe 403" do
    get "/api/v1/seller/weekly_menus", headers: auth_headers(users(:carla))

    assert_response :forbidden
    assert_equal "Seller profile required", json_response["error"]
  end

  test "index: dona ve os proprios cardapios" do
    get "/api/v1/seller/weekly_menus", headers: @headers

    assert_response :ok
    ids = json_response["menus"].map { |m| m["id"] }
    assert_equal [ @atual.id, @passado.id ].sort, ids.sort
  end

  test "index: status=past traz so o cardapio fechado" do
    get "/api/v1/seller/weekly_menus", params: { status: "past" }, headers: @headers

    assert_response :ok
    ids = json_response["menus"].map { |m| m["id"] }
    assert_equal [ @passado.id ], ids
  end

  test "show: dona ve o proprio cardapio, com os pratos" do
    get "/api/v1/seller/weekly_menus/#{@atual.id}", headers: @headers

    assert_response :ok
    menu = json_response["menu"]
    assert_equal "Cardapio da semana", menu["title"]
    assert_equal 2, menu["dishes"].size
  end

  test "show: cardapio de outro marmiteiro e 404" do
    outro = weekly_menus(:jorge_semana_atual)

    get "/api/v1/seller/weekly_menus/#{outro.id}", headers: @headers

    assert_response :not_found
    assert_equal "Menu not found", json_response["error"]
  end

  test "create: cardapio valido" do
    assert_difference -> { @marli.weekly_menus.count }, 1 do
      post "/api/v1/seller/weekly_menus",
           params: { weekly_menu: { title: "Cardapio novo", available_from: 1.day.from_now, available_until: 6.days.from_now } },
           headers: @headers
    end

    assert_response :created
    assert_equal "Daily menu created successfully", json_response["message"]
    assert_equal "Cardapio novo", json_response.dig("menu", "title")
  end

  # `title` nao tem validacao de presence no modelo (so `available_from` e
  # `available_until` tem) — por isso o campo que falta aqui e outro.
  test "create: sem available_from e 422" do
    assert_no_difference -> { @marli.weekly_menus.count } do
      post "/api/v1/seller/weekly_menus",
           params: { weekly_menu: { title: "Cardapio novo", available_until: 6.days.from_now } },
           headers: @headers
    end

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Available from can't be blank"
  end

  test "update: dona atualiza o proprio cardapio" do
    patch "/api/v1/seller/weekly_menus/#{@atual.id}", params: { weekly_menu: { title: "Novo titulo" } }, headers: @headers

    assert_response :ok
    assert_equal "Novo titulo", json_response.dig("menu", "title")
    assert_equal "Novo titulo", @atual.reload.title
  end

  test "add_dish: adiciona prato proprio a outro cardapio" do
    frango_id = dishes(:frango_grelhado).id

    assert_difference -> { @passado.weekly_menu_dishes.kept.count }, 1 do
      post "/api/v1/seller/weekly_menus/#{@passado.id}/add_dish",
           params: { dish_id: frango_id, available_quantity: 10 },
           headers: @headers
    end

    assert_response :ok
    assert_equal "Dish added to menu successfully", json_response["message"]
    dish_ids = json_response.dig("menu", "dishes").map { |d| d["dish_id"] }
    assert_includes dish_ids, frango_id
  end

  test "add_dish: prato de outro marmiteiro e 404, nao entra no cardapio" do
    outro_dish = dishes(:carne_de_panela)

    assert_no_difference -> { @atual.weekly_menu_dishes.kept.count } do
      post "/api/v1/seller/weekly_menus/#{@atual.id}/add_dish",
           params: { dish_id: outro_dish.id, available_quantity: 5 },
           headers: @headers
    end

    assert_response :not_found
    assert_equal "Dish not found", json_response["error"]
  end

  test "duplicate: cria copia com os mesmos pratos e quantidade zerada de volta ao total" do
    assert_difference -> { WeeklyMenu.count }, 1 do
      post "/api/v1/seller/weekly_menus/#{@atual.id}/duplicate", headers: @headers
    end

    assert_response :created
    novo = json_response["menu"]
    assert_not_equal @atual.id, novo["id"]
    assert_equal @atual.title, novo["title"]
    assert_not novo["active"]
    assert_equal 0, novo["total_orders_count"]
    assert_equal 2, novo["dishes"].size

    frango_copiado = novo["dishes"].find { |d| d["dish_id"] == dishes(:frango_grelhado).id }
    assert_equal 20, frango_copiado["available_quantity"]
    assert_equal 20, frango_copiado["remaining_quantity"]
    assert_equal 20.0, frango_copiado["effective_price"]

    esperado_from = @atual.available_from + 1.week
    assert_in_delta esperado_from.to_i, Time.zone.parse(novo["available_from"]).to_i, 5
  end

  test "whatsapp_text: mensagem pronta e versao url-encoded" do
    get "/api/v1/seller/weekly_menus/#{@atual.id}/whatsapp_text", headers: @headers

    assert_response :ok
    mensagem = json_response["message"]
    assert_includes mensagem, "Marmitas da Dona Marli"
    assert_includes mensagem, "Feijoada completa"
    assert_includes mensagem, "R$ 25.00"
    assert_equal ERB::Util.url_encode(mensagem), json_response["encoded_message"]
  end
end
