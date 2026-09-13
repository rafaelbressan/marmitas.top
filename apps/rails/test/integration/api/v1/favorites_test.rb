require "test_helper"

# GET/POST/DELETE /api/v1/favorites — tudo autenticado (FavoritePolicy).
class Api::V1::FavoritesTest < ActionDispatch::IntegrationTest
  setup do
    @carla = users(:carla)
    @headers = auth_headers(@carla)
  end

  test "index lista os favoritos, pratos e marmiteiros da propria conta" do
    get "/api/v1/favorites", headers: @headers

    assert_response :ok

    favoritable_ids = json_response["favorites"].map { |f| f["favoritable_id"] }
    assert_includes favoritable_ids, dishes(:feijoada).id
    assert_includes favoritable_ids, seller_profiles(:marli_marmitas).id

    assert_includes json_response["dishes"].map { |d| d["id"] }, dishes(:feijoada).id
    assert_includes json_response["sellers"].map { |s| s["id"] }, seller_profiles(:marli_marmitas).id

    prato = json_response["dishes"].find { |d| d["id"] == dishes(:feijoada).id }
    assert_equal dishes(:feijoada).name, prato["name"]
    assert prato["is_favorited"]

    marmiteira = json_response["sellers"].find { |s| s["id"] == seller_profiles(:marli_marmitas).id }
    assert_equal seller_profiles(:marli_marmitas).business_name, marmiteira["business_name"]
    assert marmiteira["is_favorited"]
  end

  test "index sem token e 401" do
    get "/api/v1/favorites"

    assert_response :unauthorized
  end

  test "dishes lista so os pratos favoritados" do
    get "/api/v1/favorites/dishes", headers: @headers

    assert_response :ok
    assert_equal [ dishes(:feijoada).id ], json_response["dishes"].map { |d| d["id"] }
  end

  test "sellers lista so os marmiteiros favoritados" do
    get "/api/v1/favorites/sellers", headers: @headers

    assert_response :ok
    assert_equal [ seller_profiles(:marli_marmitas).id ], json_response["sellers"].map { |s| s["id"] }
  end

  test "create favorita um prato novo" do
    prato = dishes(:frango_grelhado)

    assert_difference -> { @carla.favorites.count }, 1 do
      post "/api/v1/favorites",
           params: { favoritable_type: "Dish", favoritable_id: prato.id },
           headers: @headers
    end

    assert_response :created
    assert_equal "Added to favorites successfully", json_response["message"]
    assert_equal prato.id, json_response.dig("favorite", "favoritable_id")
    assert_equal "Dish", json_response.dig("favorite", "favoritable_type")
  end

  test "create sem token e 401" do
    post "/api/v1/favorites", params: { favoritable_type: "Dish", favoritable_id: dishes(:frango_grelhado).id }

    assert_response :unauthorized
  end

  test "create com tipo invalido e 422" do
    post "/api/v1/favorites",
         params: { favoritable_type: "Review", favoritable_id: dishes(:frango_grelhado).id },
         headers: @headers

    assert_response :unprocessable_entity
    assert_equal "Invalid favoritable type or ID", json_response["error"]
  end

  test "create sem favoritable_type ou id e 422" do
    post "/api/v1/favorites", params: { favoritable_type: "Dish" }, headers: @headers

    assert_response :unprocessable_entity
    assert_equal "Invalid favoritable type or ID", json_response["error"]
  end

  test "create com id inexistente e 422" do
    post "/api/v1/favorites",
         params: { favoritable_type: "Dish", favoritable_id: 0 },
         headers: @headers

    assert_response :unprocessable_entity
    assert_equal "Invalid favoritable type or ID", json_response["error"]
  end

  test "destroy remove o favorito da propria conta" do
    favorito = favorites(:carla_curte_feijoada)

    delete "/api/v1/favorites/#{favorito.id}", headers: @headers

    assert_response :ok
    assert_equal "Removed from favorites successfully", json_response["message"]
    assert_not Favorite.exists?(favorito.id)
  end

  # O destroy busca em `current_user.favorites.find`, entao o id de outra conta
  # nunca e encontrado: o 404 vem do escopo, nao de uma checagem de dono.
  test "destroy do favorito de outra conta e 404" do
    favorito_da_marli = favorites(:marli_curte_algo)

    delete "/api/v1/favorites/#{favorito_da_marli.id}", headers: @headers

    assert_response :not_found
    assert_equal "Favorite not found", json_response["error"]
    assert Favorite.exists?(favorito_da_marli.id)
  end

  test "destroy de id inexistente e 404" do
    delete "/api/v1/favorites/0", headers: @headers

    assert_response :not_found
    assert_equal "Favorite not found", json_response["error"]
  end

  test "remove tira o favorito pelo par tipo e id" do
    delete "/api/v1/favorites/remove",
           params: { favoritable_type: "Dish", favoritable_id: dishes(:feijoada).id },
           headers: @headers

    assert_response :ok
    assert_equal "Removed from favorites successfully", json_response["message"]
    assert_not @carla.favorited?(dishes(:feijoada))
  end

  test "remove de algo que nao esta favoritado e 404" do
    delete "/api/v1/favorites/remove",
           params: { favoritable_type: "Dish", favoritable_id: dishes(:frango_grelhado).id },
           headers: @headers

    assert_response :not_found
    assert_equal "Item was not favorited", json_response["error"]
  end

  test "check confirma um favorito existente" do
    get "/api/v1/favorites/check",
        params: { favoritable_type: "Dish", favoritable_id: dishes(:feijoada).id },
        headers: @headers

    assert_response :ok
    assert json_response["favorited"]
  end

  test "check nega quando o prato nao esta favoritado" do
    get "/api/v1/favorites/check",
        params: { favoritable_type: "Dish", favoritable_id: dishes(:frango_grelhado).id },
        headers: @headers

    assert_response :ok
    assert_not json_response["favorited"]
  end
end
