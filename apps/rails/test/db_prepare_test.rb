require "test_helper"
require "pg"

# Regressao da BRES-138: relato de que `bin/rails db:prepare` num banco novo
# criava o schema (via psql, `schema_format :sql`) e entao quebrava dentro do
# proprio `db:seed`, no mesmo processo, com "relation \"users\" does not
# exist" — como se o passo de seed nao enxergasse o schema recem-carregado.
#
# Roda o comando de verdade, do jeito que o DEVELOPMENT.md manda, contra um
# banco descartavel, criado do zero a cada execucao.
class DbPrepareTest < ActiveSupport::TestCase
  test "db:prepare num banco novo termina sem erro e com os dados de exemplo" do
    suffix = SecureRandom.hex(4)
    database_name = "marmitas_top_prepare_test_#{suffix}"
    test_database_name = "#{database_name}_test"

    env = {
      "RAILS_ENV" => "development",
      "DATABASE_NAME" => database_name,
      "TEST_DATABASE_NAME" => test_database_name
    }

    output = Dir.chdir(Rails.root) { IO.popen(env, [ "bin/rails", "db:create", "db:prepare" ], err: [ :child, :out ], &:read) }
    success = $?.success?

    assert success, "bin/rails db:create db:prepare falhou:\n#{output}"

    conn = PG.connect(host: db_host, port: db_port, user: db_user, password: db_password, dbname: database_name)
    admin_present = conn.exec_params("SELECT 1 FROM users WHERE email = $1", [ "admin@marmitas.top" ]).ntuples

    assert_equal 1, admin_present, "banco preparado sem os usuarios de exemplo do db/seeds.rb"
  ensure
    conn&.close
    drop_database(database_name)
    drop_database(test_database_name)
  end

  private

  def drop_database(name)
    admin = PG.connect(host: db_host, port: db_port, user: db_user, password: db_password, dbname: "postgres")
    admin.exec("DROP DATABASE IF EXISTS #{admin.quote_ident(name)}")
  ensure
    admin&.close
  end

  def db_host
    ENV.fetch("DATABASE_HOST", "localhost")
  end

  def db_port
    ENV.fetch("DATABASE_PORT", "5435").to_i
  end

  def db_user
    ENV.fetch("DATABASE_USERNAME", "marmitas")
  end

  def db_password
    ENV.fetch("DATABASE_PASSWORD", "marmitas")
  end
end
