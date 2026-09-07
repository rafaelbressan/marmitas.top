require "test_helper"

# As policies dizem quem pode; este arquivo prova que o controller pergunta.
# Cada caso e um pedido HTTP real, com o token de um papel da matriz.
class AuthorizationTest < ActionDispatch::IntegrationTest
  # A chave que fecha a porta: sem `verify_authorized` ligado, uma acao que
  # esqueca o `authorize` passa em silencio e nenhum outro teste percebe.
  test "verify_authorized esta ligado para toda a API" do
    ligado = ApplicationController._process_action_callbacks.any? do |cb|
      cb.kind == :after && cb.filter == :verify_authorized
    end

    assert ligado, "ApplicationController precisa do after_action :verify_authorized"
  end

  test "sem token o painel do marmiteiro responde 401" do
    get "/api/v1/seller/dishes"

    assert_response :unauthorized
  end

  # Antes: `current_user.seller_profile.dishes` com perfil nil estourava
  # NoMethodError e o cliente via 500.
  test "conta sem perfil de marmiteiro leva 403 no painel, nao 500" do
    get "/api/v1/seller/dishes", headers: auth_headers(users(:carla))

    assert_response :forbidden
  end

  test "um marmiteiro nao alcanca o prato do outro" do
    get "/api/v1/seller/dishes/#{dishes(:feijoada).id}", headers: auth_headers(users(:jorge))

    assert_response :not_found
  end

  test "um marmiteiro nao altera o cardapio do outro" do
    patch "/api/v1/seller/weekly_menus/#{weekly_menus(:marli_semana_atual).id}",
      params: { weekly_menu: { title: "Sequestrado" } },
      headers: auth_headers(users(:jorge))

    assert_response :not_found
    assert_equal "Cardapio da semana", weekly_menus(:marli_semana_atual).reload.title
  end

  test "um marmiteiro nao anuncia presenca no ponto de venda do outro" do
    post "/api/v1/seller/selling_locations/#{selling_locations(:largo_do_machado).id}/arrive",
      headers: auth_headers(users(:jorge))

    assert_response :not_found
    assert_not seller_profiles(:jorge_quentinhas).reload.currently_active
  end

  test "o painel de moderacao e do admin" do
    get "/api/v1/admin/reviews"
    assert_response :unauthorized

    get "/api/v1/admin/reviews", headers: auth_headers(users(:carla))
    assert_response :forbidden

    get "/api/v1/admin/reviews", headers: auth_headers(users(:marli))
    assert_response :forbidden

    get "/api/v1/admin/reviews", headers: auth_headers(users(:admin))
    assert_response :success
  end

  test "o marmiteiro avaliado nao remove a avaliacao sobre si mesmo" do
    review = reviews(:diego_sobre_marli)

    post "/api/v1/admin/reviews/#{review.id}/remove",
      params: { note: "nao gostei" },
      headers: auth_headers(users(:marli))

    assert_response :forbidden
    assert_equal "published", review.reload.moderation_status
  end

  # Antes: `@review.editable_by?(current_user)` com `current_user` nil dava
  # NoMethodError numa acao publica.
  test "ler uma avaliacao sem token responde 200 e sem permissao nenhuma" do
    get "/api/v1/reviews/#{reviews(:carla_sobre_marli).id}"

    assert_response :success
    permissoes = response.parsed_body["permissions"]
    assert_equal({ "can_edit" => false, "can_flag" => false, "can_mark_helpful" => false }, permissoes)
  end

  test "so quem escreveu edita a avaliacao" do
    review = reviews(:carla_sobre_marli)

    patch "/api/v1/reviews/#{review.id}",
      params: { review: { rating: 1, comment: "Editado por outra pessoa" } },
      headers: auth_headers(users(:diego))

    assert_response :forbidden
    assert_equal 5, review.reload.rating
  end

  test "ninguem apaga o favorito de outra pessoa" do
    delete "/api/v1/favorites/#{favorites(:carla_segue_marli).id}", headers: auth_headers(users(:diego))

    assert_response :not_found
    assert Favorite.exists?(favorites(:carla_segue_marli).id)
  end

  test "ninguem apaga o token de push de outro aparelho" do
    delete "/api/v1/device_tokens/#{device_tokens(:carla_iphone).id}", headers: auth_headers(users(:diego))

    assert_response :not_found
    assert DeviceToken.exists?(device_tokens(:carla_iphone).id)
  end
end
