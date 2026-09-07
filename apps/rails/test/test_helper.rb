ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers.
    #
    # Cada worker ganha o proprio banco (`marmitas_top_test_0`, `_1`, ...), criado
    # a partir do `db/structure.sql`. Como o schema e versionado em SQL, o dump
    # comeca com `CREATE EXTENSION IF NOT EXISTS postgis` e cada banco paralelo
    # nasce com a extensao, a coluna `geography` e o indice GiST. Com o
    # `db/schema.rb` antigo os bancos paralelos sairiam ate sem a tabela
    # `selling_locations`. Para conferir:
    #
    #   PARALLEL_WORKERS=3 bin/rails test
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ActionDispatch
  class IntegrationTest
    # Token do proprio devise-jwt, com a mesma chave e o mesmo encoder que o
    # POST /auth/login usa. Evita passar por login em todo teste de rota.
    def auth_headers(user)
      token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
      { "Authorization" => "Bearer #{token}" }
    end
  end
end
