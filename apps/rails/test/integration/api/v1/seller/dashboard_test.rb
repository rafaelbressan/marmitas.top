require "test_helper"

# GET /api/v1/seller/dashboard — o resumo do dia da tela "Minha loja".
#
# Os dois estados que a tela precisa desenhar sao a Marli (cardapio no ar,
# avaliacoes, seguidor) e a Bia (primeiro dia de uso, nada dentro do perfil).
class Api::V1::Seller::DashboardTest < ActionDispatch::IntegrationTest
  URL = "/api/v1/seller/dashboard".freeze

  test "sem token o painel responde 401" do
    get URL

    assert_response :unauthorized
  end

  test "quem nao tem perfil de marmiteiro nao tem painel" do
    get URL, headers: auth_headers(users(:carla))

    assert_response :forbidden
    assert_equal "Você precisa criar um perfil de marmiteiro antes de ver o painel.",
                 json_response["error"]
  end

  test "marmiteira com cardapio no ar ve seguidores, nota, avaliacoes, pratos e o dia" do
    get URL, headers: auth_headers(users(:marli))

    assert_response :ok
    painel = json_response["dashboard"]

    perfil = painel["profile"]
    assert_equal seller_profiles(:marli_marmitas).id, perfil["id"]
    assert_equal "Marmitas da Dona Marli", perfil["business_name"]
    assert_equal 1, perfil["followers_count"]
    assert perfil["currently_active"]
    assert_equal "Largo do Machado", perfil.dig("current_location", "name")

    nota = painel["rating"]
    assert_equal 2, nota["reviews_count"]
    # Com 2 avaliacoes a nota nao aparece: o minimo de `display_rating?` e 5.
    assert_not nota["display"]
    assert_equal({ "1" => 0, "2" => 0, "3" => 0, "4" => 1, "5" => 1 }, nota["distribution"])
    assert_equal "stable", nota["trend"]

    avaliacoes = painel["recent_reviews"]
    assert_equal [ 4, 5 ], avaliacoes.map { |a| a["rating"] }.sort
    assert_equal [ "Carla Ferraz", "Diego Muniz" ], avaliacoes.map { |a| a["author_name"] }.sort
    assert_includes avaliacoes.map { |a| a["dish_name"] }, "Feijoada completa"

    pratos = painel["top_dishes"]
    assert_equal 1, pratos["total_favorites"]
    assert_equal "Feijoada completa", pratos["dishes"].first["name"]
    assert_equal 100.0, pratos["dishes"].first["percentage"]

    # marli_feijoada: 20 anunciadas, 8 restantes. marli_frango: 20 e 15.
    dia = painel["today"]
    assert_equal weekly_menus(:marli_semana_atual).id, dia.dig("menu", "id")
    assert_equal 40, dia["announced_quantity"]
    assert_equal 23, dia["remaining_quantity"]
    assert_equal 17, dia["sold_quantity"]

    feijoada = dia["dishes"].find { |p| p["name"] == "Feijoada completa" }
    assert_equal 12, feijoada["sold_quantity"]
    assert_equal 25.0, feijoada["price"]

    # `price_override` do cardapio ganha do `base_price` de 22,00 do prato.
    frango = dia["dishes"].find { |p| p["name"] == "Frango grelhado com legumes" }
    assert_equal 20.0, frango["price"]
  end

  test "o cardapio da semana passada nao entra no resumo do dia" do
    get URL, headers: auth_headers(users(:marli))

    assert_response :ok
    # marli_feijoada_semana_passada anunciou 25 unidades; se o resumo somasse
    # cardapio fechado o total anunciado seria 65, nao 40.
    assert_equal 40, json_response.dig("dashboard", "today", "announced_quantity")
  end

  test "o painel e sempre o de quem pediu, nunca o de outro marmiteiro" do
    get URL, headers: auth_headers(users(:jorge))

    assert_response :ok
    painel = json_response["dashboard"]

    assert_equal seller_profiles(:jorge_quentinhas).id, painel.dig("profile", "id")
    assert_equal "Quentinhas do Seu Jorge", painel.dig("profile", "business_name")
    assert_equal weekly_menus(:jorge_semana_atual).id, painel.dig("today", "menu", "id")
    assert_equal 30, painel.dig("today", "announced_quantity")
    assert_equal 0, painel.dig("today", "sold_quantity")

    # A avaliacao que o Jorge tem esta sob moderacao: nao aparece para ele.
    assert_empty painel["recent_reviews"]
    assert_equal 0, painel.dig("rating", "reviews_count")
  end

  test "marmiteira sem cardapio hoje recebe o painel zerado, nao um erro" do
    get URL, headers: auth_headers(users(:bia))

    assert_response :ok
    painel = json_response["dashboard"]

    assert_equal "Marmitas da Bia", painel.dig("profile", "business_name")
    assert_nil painel.dig("profile", "current_location")
    assert_equal 0, painel.dig("profile", "followers_count")

    assert_not painel.dig("rating", "display")
    assert_equal 0, painel.dig("rating", "reviews_count")
    assert_empty painel["recent_reviews"]

    assert_equal 0, painel.dig("top_dishes", "total_favorites")
    assert_empty painel.dig("top_dishes", "dishes")

    dia = painel["today"]
    assert_nil dia["menu"]
    assert_equal 0, dia["announced_quantity"]
    assert_equal 0, dia["remaining_quantity"]
    assert_equal 0, dia["sold_quantity"]
    assert_empty dia["dishes"]
  end

  test "o painel nao faz uma consulta por prato nem por avaliacao" do
    consultas = []
    assinatura = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      consultas << payload[:sql] unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ])
    end

    get URL, headers: auth_headers(users(:marli))

    assert_response :ok
    # A Marli tem 2 pratos no cardapio e 2 avaliacoes. O painel monta tudo com um
    # numero fixo de consultas; se virar N+1 esse teto estoura assim que uma
    # marmiteira real tiver dezenas de pratos.
    assert_operator consultas.size, :<=, 20, "consultas emitidas:\n#{consultas.join("\n")}"
  ensure
    ActiveSupport::Notifications.unsubscribe(assinatura) if assinatura
  end
end
