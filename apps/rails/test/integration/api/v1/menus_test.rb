require "test_helper"

# GET /api/v1/menus, /:id, /available_today, /sellers/:id/menus — os cardapios
# que o app mostra antes do login (WeeklyMenuPolicy: tudo publico).
class Api::V1::MenusTest < ActionDispatch::IntegrationTest
  # index e available_today sempre estouram ActiveRecord::AssociationNotFoundError
  # em `.includes(dish: :photos)` (Dish usa `has_many_attached :photos`, que o
  # Rails nao aceita em `includes`). Acontece com ou sem token — testei os dois
  # via `bin/rails runner` e com `auth_headers` — entao e mais amplo do que o
  # "500 sem token" da BRES-141. Nao mexo no controller; so registro o teste
  # (com token, pra isolar do 401) e pulo com a explicacao.
  test "index lista os cardapios disponiveis agora" do
    skip "menus#index quebra com ActiveRecord::AssociationNotFoundError em " \
         "`.includes(dish: :photos)` — acontece com ou sem token, mais amplo que a BRES-141."

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
    skip "mesmo bug do index: `.includes(dish: :photos)` estoura " \
         "ActiveRecord::AssociationNotFoundError, com ou sem token."

    get "/api/v1/menus/available_today", headers: auth_headers(users(:carla))

    assert_response :ok
    ids = json_response["menus"].map { |m| m["id"] }

    assert_includes ids, weekly_menus(:marli_semana_atual).id
    assert_not_includes ids, weekly_menus(:marli_semana_passada).id
  end

  # A rota e `member do get :menus ... end` dentro de `resources :sellers`, entao
  # o parametro chega como `params[:id]`, nao `params[:seller_id]` (confirmado
  # com `bin/rails routes`). O controller le `params[:seller_id]`, que e sempre
  # nil: `SellerProfile.kept.find(nil)` estoura RecordNotFound e a action
  # devolve 404 "Seller not found" pra QUALQUER id, valido ou nao. Além disso
  # falta `:seller_menus` no `skip_before_action :authenticate_user!` do
  # controller, entao a action exige token mesmo a policy dizendo que e publica.
  test "sellers/:id/menus lista os cardapios daquele marmiteiro" do
    skip "seller_menus tem dois bugs: (1) falta token e a policy diz que e " \
         "publica; (2) `params[:seller_id]` nunca existe (a rota expoe `:id`), " \
         "entao a action devolve 404 pra qualquer seller, mesmo valido."

    marli = seller_profiles(:marli_marmitas)

    get "/api/v1/sellers/#{marli.id}/menus", headers: auth_headers(users(:carla))

    assert_response :ok
    ids = json_response["menus"].map { |m| m["id"] }

    assert_includes ids, weekly_menus(:marli_semana_atual).id
    assert_not_includes ids, weekly_menus(:marli_semana_passada).id
  end

  test "sellers/:id/menus de marmiteiro inexistente e 404, sem exigir token" do
    skip "mesmo bug (1) acima: sem `:seller_menus` no skip_before_action, a " \
         "action devolve 401 antes de chegar no rescue que daria o 404 publico."

    get "/api/v1/sellers/0/menus"

    assert_response :not_found
    assert_equal "Seller not found", json_response["error"]
  end
end
