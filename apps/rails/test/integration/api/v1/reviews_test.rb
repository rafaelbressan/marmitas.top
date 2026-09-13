require "test_helper"

# BRES-141: `GET /api/v1/reviews/:id` e publico (`skip_before_action
# :authenticate_user!, only: [:index, :show]`), mas antes chamava
# `@review.editable_by?(current_user)` direto, e esse metodo faz
# `current_user.id` de cara. Sem token isso estourava `NoMethodError` (500).
# A ReviewPolicy corrigiu isso guardando com `signed_in?` antes de chamar o
# model; este teste prova o comportamento pela API, nao so pela policy.
class Api::V1::ReviewsTest < ActionDispatch::IntegrationTest
  test "GET /api/v1/reviews/:id sem token responde 200 com permissoes false" do
    review = reviews(:carla_sobre_marli)

    get "/api/v1/reviews/#{review.id}"

    assert_response :ok
    assert_equal review.id, json_response.dig("review", "id")
    assert_equal({
      "can_edit" => false,
      "can_flag" => false,
      "can_mark_helpful" => false
    }, json_response["permissions"])
  end

  test "GET /api/v1/reviews/:id com token da autora permite editar, nao denunciar nem marcar util" do
    review = reviews(:carla_sobre_marli)

    get "/api/v1/reviews/#{review.id}", headers: auth_headers(users(:carla))

    assert_response :ok
    assert_equal({
      "can_edit" => true,
      "can_flag" => false,
      "can_mark_helpful" => false
    }, json_response["permissions"])
  end

  test "GET /api/v1/reviews/:id com token de outra pessoa permite denunciar e marcar util, nao editar" do
    review = reviews(:carla_sobre_marli)

    get "/api/v1/reviews/#{review.id}", headers: auth_headers(users(:diego))

    assert_response :ok
    assert_equal({
      "can_edit" => false,
      "can_flag" => true,
      "can_mark_helpful" => true
    }, json_response["permissions"])
  end
end
