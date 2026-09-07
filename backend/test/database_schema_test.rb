require "test_helper"

# Guarda de regressao do motivo pelo qual ninguem conseguia subir o projeto: o
# `db/schema.rb` nao sabia representar a coluna `geography` e descartava a tabela
# `selling_locations` inteira do dump, entao todo banco criado com `db:prepare`
# ou `db:schema:load` nascia sem a tabela central do produto.
#
# Roda contra o banco do worker atual, entao com `parallelize` ligado ele confere
# tambem os bancos paralelos (`marmitas_top_test_0`, `_1`, ...).
class DatabaseSchemaTest < ActiveSupport::TestCase
  def connection
    ActiveRecord::Base.connection
  end

  test "o schema e versionado como structure.sql" do
    assert_equal :sql, Rails.application.config.active_record.schema_format
    assert_path_exists Rails.root.join("db/structure.sql")
  end

  test "a extensao postgis esta habilitada" do
    assert_includes connection.extensions, "postgis"
  end

  test "a tabela selling_locations existe" do
    assert connection.table_exists?("selling_locations")
  end

  test "lonlat continua sendo uma coluna geography" do
    lonlat = connection.columns("selling_locations").find { |c| c.name == "lonlat" }

    assert_not_nil lonlat, "a coluna lonlat sumiu de selling_locations"
    assert_equal "geography", lonlat.sql_type
  end

  # Pega a armadilha do `parallelize`: ao reaproveitar um banco de teste, o Rails
  # trunca todas as tabelas, e sem o guarda de config/initializers/postgis.rb ele
  # leva `spatial_ref_sys` junto. Quando isso acontece, a primeira rodada passa e
  # a segunda quebra com "Cannot find SRID (4326)".
  test "spatial_ref_sys continua populada, senao nenhum ST_ com SRID 4326 funciona" do
    srids = connection.select_value("SELECT COUNT(*) FROM public.spatial_ref_sys")

    assert_operator srids, :>, 0, "spatial_ref_sys esta vazia — o truncate levou os SRIDs do PostGIS"
    assert_equal 1, connection.select_value("SELECT COUNT(*) FROM public.spatial_ref_sys WHERE srid = 4326")
  end

  test "lonlat tem indice GiST, senao a busca por proximidade varre a tabela" do
    index = connection.indexes("selling_locations").find { |i| i.columns == [ "lonlat" ] }

    assert_not_nil index, "falta o indice em lonlat"
    assert_equal :gist, index.using
  end
end
