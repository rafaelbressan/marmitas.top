require "test_helper"

# GET /api/v1/admin/reviews, GET /api/v1/admin/reviews/:id,
# POST /api/v1/admin/reviews/:id/approve, POST /api/v1/admin/reviews/:id/remove
class Api::V1::Admin::ReviewsTest < ActionDispatch::IntegrationTest
  setup do
    @em_moderacao = reviews(:diego_sobre_jorge_em_moderacao)
    @publicada = reviews(:carla_sobre_marli)
    @admin_headers = auth_headers(users(:admin))
  end

  # --- index ---

  test "admin ve a fila de moderacao, que exclui avaliacao so publicada" do
    get "/api/v1/admin/reviews", headers: @admin_headers

    assert_response :ok
    ids = json_response["reviews"].map { |r| r["id"] }
    assert_includes ids, @em_moderacao.id
    assert_not_includes ids, @publicada.id
    assert_equal 1, json_response.dig("stats", "total_pending")
  end

  test "quem nao e admin nao ve a fila de moderacao" do
    get "/api/v1/admin/reviews", headers: auth_headers(users(:carla))

    assert_response :forbidden
    assert_equal "Acesso não autorizado", json_response["error"]
  end

  test "sem token nao acessa a fila de moderacao" do
    get "/api/v1/admin/reviews"

    assert_response :unauthorized
  end

  test "filtro status=under_review so devolve avaliacao sob moderacao" do
    get "/api/v1/admin/reviews", params: { status: "under_review" }, headers: @admin_headers

    assert_response :ok
    assert_equal [ @em_moderacao.id ], json_response["reviews"].map { |r| r["id"] }
  end

  # --- show ---

  test "admin ve detalhe da avaliacao com padroes suspeitos e historico" do
    get "/api/v1/admin/reviews/#{@em_moderacao.id}", headers: @admin_headers

    assert_response :ok
    body = json_response
    assert body.key?("suspicious_patterns")
    assert body.key?("user_history")
    assert_equal @em_moderacao.id, body.dig("review", "id")
  end

  test "quem nao e admin nao ve detalhe da avaliacao" do
    get "/api/v1/admin/reviews/#{@em_moderacao.id}", headers: auth_headers(users(:diego))

    assert_response :forbidden
  end

  test "detalhe de id inexistente da 404 para admin" do
    get "/api/v1/admin/reviews/0", headers: @admin_headers

    assert_response :not_found
  end

  # --- approve ---

  test "admin aprova avaliacao sob moderacao" do
    post "/api/v1/admin/reviews/#{@em_moderacao.id}/approve",
         params: { note: "Revisado, sem problema." },
         headers: @admin_headers

    assert_response :ok
    @em_moderacao.reload
    assert_equal "published", @em_moderacao.moderation_status
    assert_equal users(:admin).id, @em_moderacao.moderated_by_id
    assert_not_nil @em_moderacao.moderated_at
  end

  test "quem nao e admin nao aprova avaliacao" do
    post "/api/v1/admin/reviews/#{@em_moderacao.id}/approve",
         params: { note: "Tentando aprovar sem ser admin." },
         headers: auth_headers(users(:diego))

    assert_response :forbidden
    assert_equal "under_review", @em_moderacao.reload.moderation_status
  end

  # --- remove ---

  test "admin remove avaliacao com nota" do
    post "/api/v1/admin/reviews/#{@em_moderacao.id}/remove",
         params: { note: "Conteudo ofensivo confirmado." },
         headers: @admin_headers

    assert_response :ok
    assert_equal "removed", @em_moderacao.reload.moderation_status
  end

  test "remover sem nota e erro" do
    post "/api/v1/admin/reviews/#{@em_moderacao.id}/remove",
         params: {},
         headers: @admin_headers

    assert_response :unprocessable_entity
    assert_equal "Nota é obrigatória ao remover avaliação", json_response["error"]
    assert_equal "under_review", @em_moderacao.reload.moderation_status
  end

  test "quem nao e admin nao remove avaliacao" do
    post "/api/v1/admin/reviews/#{@em_moderacao.id}/remove",
         params: { note: "Tentando remover sem ser admin." },
         headers: auth_headers(users(:diego))

    assert_response :forbidden
    assert_equal "under_review", @em_moderacao.reload.moderation_status
  end
end
