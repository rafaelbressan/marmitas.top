require "test_helper"

# POST /api/v1/auth/register, /login, DELETE /logout, GET /me — a porta de
# entrada da API. Nao ha usuario antes de `register`/`login`, por isso essas
# duas acoes ficam fora do `verify_authorized` (ver auth_controller.rb).
class Api::V1::AuthTest < ActionDispatch::IntegrationTest
  test "cadastro cria o usuario e devolve um token que autentica de verdade" do
    assert_difference -> { User.count }, 1 do
      post "/api/v1/auth/register", params: {
        user: {
          email: "nova.marmiteira@example.com",
          password: "senha123",
          password_confirmation: "senha123",
          name: "Nova Marmiteira",
          phone: "21988110099"
        }
      }
    end

    assert_response :created
    assert_equal "Registration successful", json_response["message"]
    assert_equal "nova.marmiteira@example.com", json_response.dig("user", "email")
    assert_not json_response.dig("user", "is_seller")

    token = json_response["token"]
    assert token.present?

    # O token devolvido no cadastro autentica de verdade, nao e so uma string.
    get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :ok
    assert_equal "nova.marmiteira@example.com", json_response.dig("user", "email")
  end

  test "cadastro sem email nao cria usuario e devolve os erros" do
    assert_no_difference -> { User.count } do
      post "/api/v1/auth/register", params: {
        user: {
          email: "",
          password: "senha123",
          password_confirmation: "senha123",
          name: "Sem Email"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Email can't be blank"
  end

  test "cadastro com senha curta nao cria usuario" do
    assert_no_difference -> { User.count } do
      post "/api/v1/auth/register", params: {
        user: {
          email: "senha.curta@example.com",
          password: "123",
          password_confirmation: "123",
          name: "Senha Curta"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_not_empty json_response["errors"]
  end

  test "cadastro com email ja usado nao cria um segundo usuario" do
    carla = users(:carla)

    assert_no_difference -> { User.count } do
      post "/api/v1/auth/register", params: {
        user: {
          email: carla.email,
          password: "senha123",
          password_confirmation: "senha123",
          name: "Outra Carla"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Email has already been taken"
  end

  test "login com email e senha certos devolve o usuario e um token" do
    post "/api/v1/auth/login", params: {
      user: { email: users(:carla).email, password: "senha123" }
    }

    assert_response :ok
    assert_equal "Login successful", json_response["message"]
    assert_equal users(:carla).id, json_response.dig("user", "id")
    assert json_response["token"].present?
  end

  test "login com senha errada nao entra" do
    post "/api/v1/auth/login", params: {
      user: { email: users(:carla).email, password: "senha-errada" }
    }

    assert_response :unauthorized
    assert_equal "Invalid email or password", json_response["error"]
  end

  test "login com email desconhecido nao entra" do
    post "/api/v1/auth/login", params: {
      user: { email: "ninguem@example.com", password: "senha123" }
    }

    assert_response :unauthorized
    assert_equal "Invalid email or password", json_response["error"]
  end

  test "me sem token e 401" do
    get "/api/v1/auth/me"

    assert_response :unauthorized
  end

  test "me com token devolve o usuario dono do token" do
    get "/api/v1/auth/me", headers: auth_headers(users(:marli))

    assert_response :ok
    assert_equal users(:marli).id, json_response.dig("user", "id")
    assert_equal users(:marli).email, json_response.dig("user", "email")
    assert json_response.dig("user", "is_seller")
    assert json_response.dig("user", "has_seller_profile")
  end

  test "logout sem token e 401" do
    delete "/api/v1/auth/logout"

    assert_response :unauthorized
  end

  test "logout com token encerra a sessao" do
    delete "/api/v1/auth/logout", headers: auth_headers(users(:diego))

    assert_response :ok
    assert_equal "Logged out successfully", json_response["message"]
  end
end
