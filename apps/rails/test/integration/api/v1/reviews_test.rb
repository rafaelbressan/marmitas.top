require "test_helper"

# GET/POST /api/v1/sellers/:seller_id/reviews, GET/PATCH/DELETE
# /api/v1/reviews/:id, POST /api/v1/reviews/:id/flag e /helpful.
class Api::V1::ReviewsTest < ActionDispatch::IntegrationTest
  setup do
    @marli = seller_profiles(:marli_marmitas)
    @jorge = seller_profiles(:jorge_quentinhas)
    @carla_sobre_marli = reviews(:carla_sobre_marli)
    @diego_sobre_marli = reviews(:diego_sobre_marli)
    @em_moderacao = reviews(:diego_sobre_jorge_em_moderacao)
  end

  # --- index (nested em seller) ---

  test "lista apenas avaliacoes publicadas do marmiteiro" do
    get "/api/v1/sellers/#{@marli.id}/reviews"

    assert_response :ok
    assert_equal [ @carla_sobre_marli.id, @diego_sobre_marli.id ].sort,
                 json_response["reviews"].map { |r| r["id"] }.sort
  end

  test "avaliacao sob moderacao nao aparece na lista do marmiteiro" do
    get "/api/v1/sellers/#{@jorge.id}/reviews"

    assert_response :ok
    assert_empty json_response["reviews"]
  end

  test "seller_id inexistente da 404" do
    get "/api/v1/sellers/0/reviews"

    assert_response :not_found
    assert json_response["error"].present?
  end

  test "filtro rating so devolve avaliacoes com aquela nota" do
    get "/api/v1/sellers/#{@marli.id}/reviews", params: { rating: 5 }

    assert_response :ok
    assert_equal [ @carla_sobre_marli.id ], json_response["reviews"].map { |r| r["id"] }
  end

  # --- create ---

  test "cria avaliacao com sucesso e bloqueia segunda avaliacao do mesmo marmiteiro no mesmo dia" do
    assert_difference -> { Review.count }, 1 do
      post "/api/v1/sellers/#{@marli.id}/reviews",
           params: { review: {
             rating: 3,
             comment: "Comida ok, chegou no horario.",
             encounter_timestamp: Time.current,
             weekly_menu_id: weekly_menus(:marli_semana_atual).id
           } },
           headers: auth_headers(users(:carla))
    end

    assert_response :created
    body = json_response
    assert_equal "Avaliação criada com sucesso", body["message"]
    assert_equal 3, body.dig("review", "rating")
    assert_equal "Comida ok, chegou no horario.", body.dig("review", "comment")
    assert_equal users(:carla).id, body.dig("review", "user", "id")

    # Carla ja tem `carla_sobre_marli`, mas com `encounter_date` de 3 dias atras:
    # a avaliacao acima nao colide porque o dia e diferente. Uma segunda hoje,
    # sim.
    post "/api/v1/sellers/#{@marli.id}/reviews",
         params: { review: { rating: 4, comment: "De novo hoje.", encounter_timestamp: Time.current } },
         headers: auth_headers(users(:carla))

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "User Você já avaliou este marmiteiro hoje"
  end

  test "criar sem rating e erro de validacao" do
    post "/api/v1/sellers/#{@jorge.id}/reviews",
         params: { review: { comment: "Sem nota.", encounter_timestamp: Time.current } },
         headers: auth_headers(users(:ana))

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Rating can't be blank"
  end

  test "marmiteiro nao pode avaliar o proprio negocio" do
    post "/api/v1/sellers/#{@marli.id}/reviews",
         params: { review: { rating: 5, comment: "Meu proprio feijao e bom.", encounter_timestamp: Time.current } },
         headers: auth_headers(users(:marli))

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Você não pode avaliar seu próprio negócio"
  end

  test "sem token nao cria avaliacao" do
    assert_no_difference -> { Review.count } do
      post "/api/v1/sellers/#{@marli.id}/reviews",
           params: { review: { rating: 5, encounter_timestamp: Time.current } }
    end

    assert_response :unauthorized
  end

  test "nota extrema sem comentario e erro de validacao" do
    post "/api/v1/sellers/#{@jorge.id}/reviews",
         params: { review: { rating: 1, encounter_timestamp: Time.current } },
         headers: auth_headers(users(:ana))

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Comment can't be blank"
  end

  # --- show ---

  test "show devolve as permissoes do autor" do
    get "/api/v1/reviews/#{@carla_sobre_marli.id}", headers: auth_headers(users(:carla))

    assert_response :ok
    permissions = json_response["permissions"]
    assert permissions["can_edit"]
    assert_not permissions["can_flag"], "autor nao pode denunciar a propria avaliacao"
    assert_not permissions["can_mark_helpful"], "autor nao pode marcar a propria avaliacao como util"
  end

  test "show devolve as permissoes de outro usuario logado" do
    get "/api/v1/reviews/#{@carla_sobre_marli.id}", headers: auth_headers(users(:diego))

    assert_response :ok
    permissions = json_response["permissions"]
    assert_not permissions["can_edit"]
    assert permissions["can_flag"]
    assert permissions["can_mark_helpful"]
  end

  test "show devolve permissoes todas falsas para visitante anonimo" do
    get "/api/v1/reviews/#{@carla_sobre_marli.id}"

    assert_response :ok
    permissions = json_response["permissions"]
    assert_not permissions["can_edit"]
    assert_not permissions["can_flag"]
    assert_not permissions["can_mark_helpful"]
  end

  test "show de id inexistente da 404" do
    get "/api/v1/reviews/0"

    assert_response :not_found
  end

  # --- update ---

  test "autor edita a propria avaliacao dentro da janela" do
    patch "/api/v1/reviews/#{@carla_sobre_marli.id}",
          params: { review: { rating: 4, comment: "Revendo: ainda bom, mas nao tanto." } },
          headers: auth_headers(users(:carla))

    assert_response :ok
    body = json_response
    assert_equal 4, body.dig("review", "rating")
    assert_equal 1, @carla_sobre_marli.reload.edit_count
    assert_not_nil @carla_sobre_marli.last_edited_at
  end

  test "quem nao e autor nao consegue editar" do
    # `ReviewPolicy#update?` nega e o `authorize` levanta
    # `Pundit::NotAuthorizedError`, capturado pelo `rescue_from` do
    # ApplicationController -> 403. Nao e um erro de validacao do model (422).
    patch "/api/v1/reviews/#{@carla_sobre_marli.id}",
          params: { review: { rating: 1, comment: "Tentando editar a avaliacao de outra pessoa." } },
          headers: auth_headers(users(:diego))

    assert_response :forbidden
    assert_equal 5, @carla_sobre_marli.reload.rating
  end

  test "sem token nao edita" do
    patch "/api/v1/reviews/#{@carla_sobre_marli.id}",
          params: { review: { rating: 4 } }

    assert_response :unauthorized
  end

  test "editar id inexistente da 404" do
    patch "/api/v1/reviews/0",
          params: { review: { rating: 4 } },
          headers: auth_headers(users(:carla))

    assert_response :not_found
  end

  # --- destroy ---
  # A discard_test.rb ja cobre o dono descartando a propria avaliacao; aqui so
  # falta o no-author.

  test "quem nao e autor nao consegue apagar a avaliacao de outra pessoa" do
    delete "/api/v1/reviews/#{@carla_sobre_marli.id}", headers: auth_headers(users(:diego))

    assert_response :forbidden
    assert_not @carla_sobre_marli.reload.discarded?
  end

  # --- flag ---

  test "outro usuario denuncia avaliacao publicada" do
    post "/api/v1/reviews/#{@carla_sobre_marli.id}/flag",
         params: { reason: "Comentario parece falso." },
         headers: auth_headers(users(:diego))

    assert_response :ok
    @carla_sobre_marli.reload
    assert @carla_sobre_marli.flagged
    assert_equal "under_review", @carla_sobre_marli.moderation_status
  end

  test "autor nao pode denunciar a propria avaliacao" do
    # `flaggable_by?` nega, `authorize` levanta `Pundit::NotAuthorizedError` -> 403.
    post "/api/v1/reviews/#{@carla_sobre_marli.id}/flag",
         params: { reason: "Motivo qualquer." },
         headers: auth_headers(users(:carla))

    assert_response :forbidden
    assert_not @carla_sobre_marli.reload.flagged
  end

  test "nao da para denunciar avaliacao ja denunciada" do
    post "/api/v1/reviews/#{@carla_sobre_marli.id}/flag",
         params: { reason: "Primeira denuncia." },
         headers: auth_headers(users(:diego))
    assert_response :ok

    post "/api/v1/reviews/#{@carla_sobre_marli.id}/flag",
         params: { reason: "Segunda denuncia." },
         headers: auth_headers(users(:ana))

    assert_response :forbidden
  end

  test "sem token nao denuncia" do
    post "/api/v1/reviews/#{@carla_sobre_marli.id}/flag", params: { reason: "Motivo." }

    assert_response :unauthorized
  end

  # --- helpful ---

  test "marcar e desmarcar avaliacao como util alterna o contador" do
    assert_equal 1, @carla_sobre_marli.helpful_count

    post "/api/v1/reviews/#{@carla_sobre_marli.id}/helpful", headers: auth_headers(users(:ana))

    assert_response :ok
    assert json_response["is_helpful"]
    assert_equal 2, json_response["helpful_count"]

    post "/api/v1/reviews/#{@carla_sobre_marli.id}/helpful", headers: auth_headers(users(:ana))

    assert_response :ok
    assert_not json_response["is_helpful"]
    assert_equal 1, json_response["helpful_count"]
  end

  test "autor nao pode marcar a propria avaliacao como util" do
    # `ReviewPolicy#helpful?` e `signed_in? && !authored_record?`: para o autor
    # da falso antes de chegar em `toggle_helpful`. `authorize` levanta
    # `Pundit::NotAuthorizedError` -> 403.
    post "/api/v1/reviews/#{@carla_sobre_marli.id}/helpful", headers: auth_headers(users(:carla))

    assert_response :forbidden
    assert_equal 1, @carla_sobre_marli.reload.helpful_count
  end

  test "sem token nao marca como util" do
    post "/api/v1/reviews/#{@carla_sobre_marli.id}/helpful"

    assert_response :unauthorized
  end
end
