require "test_helper"

# Regressao da BRES-143.
#
# O `json` 3.0 tirou o segundo argumento de `JSON.parse`, e o
# `ActiveSupport::JSON.decode` do Rails 8.1 ainda chama
# `JSON.parse(json, quirks_mode: true)`. Com `json (3.0.0)` no `Gemfile.lock`,
# LER qualquer coluna `jsonb` levanta
# `ArgumentError: wrong number of arguments (given 2, expected 1)` — 500 em toda
# resposta que serializa uma dessas colunas, e ate o `db:seed` para.
#
# Nenhum outro teste passava por esse caminho: o atributo `jsonb` so e
# desserializado quando alguem o le, e o `fixtures_test` so chama `valid?`. Por
# isso o pin de `json` no Gemfile precisa deste teste do lado — sem ele o
# proximo `bundle update` derruba o pin com os quatro gates verdes.
#
# Uma coluna por modelo: sao as tres que existem no `db/structure.sql`.
class JsonbColumnsTest < ActiveSupport::TestCase
  test "le dishes.dietary_tags" do
    prato = Dish.find(dishes(:frango_grelhado).id)

    assert_equal [ "gluten_free", "low_carb" ], prato.dietary_tags
  end

  test "le seller_profiles.operating_hours" do
    perfil = SellerProfile.find(seller_profiles(:marli_marmitas).id)

    assert_equal({ "open" => "11:00", "close" => "14:00" }, perfil.operating_hours["monday"])
  end

  test "le users.notification_preferences" do
    usuario = User.find(users(:carla).id)

    assert_equal(
      { "new_menus" => false, "promotions" => true, "order_updates" => true, "seller_arrivals" => false },
      usuario.notification_preferences
    )
  end
end
