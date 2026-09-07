require "test_helper"

# O teste que faltava. O `json` 3.0 tirou o segundo argumento de `JSON.parse`, e
# `ActiveSupport::JSON.decode` ainda passa `quirks_mode: true` — com ele no
# lock, toda leitura de coluna `jsonb` estoura com ArgumentError e o endpoint
# responde 500. Os quatro gates do CI ficaram verdes assim mesmo, porque nenhum
# teste lia uma dessas colunas — foi por isso que o problema chegou a `master`.
#
# O pino (`gem "json", "< 3.0"`) chegou pela BRES-128; o que faltava era o
# teste que o segura. Se ele cair num `bundle update`, e aqui que a build para.
class JsonbColumnsTest < ActiveSupport::TestCase
  test "dietary_tags de um prato le como array" do
    prato = dishes(:frango_grelhado)

    assert_equal %w[gluten_free low_carb], prato.dietary_tags
    assert_equal "Gluten free, Low carb", prato.dietary_tags_display
  end

  test "operating_hours de um marmiteiro le como hash" do
    horarios = seller_profiles(:marli_marmitas).operating_hours

    assert_kind_of Hash, horarios
    assert_equal "11:00", horarios.dig("monday", "open")
  end

  test "notification_preferences de um usuario le como hash" do
    assert_kind_of Hash, users(:carla).notification_preferences
  end

  # O caminho que quebrava em producao: o JSON da resposta, nao so o atributo.
  test "a lista de pratos do painel serializa as colunas jsonb" do
    prato = dishes(:frango_grelhado)

    resposta = {
      dietary_tags: prato.dietary_tags,
      operating_hours: prato.seller_profile.operating_hours
    }.to_json

    assert_includes resposta, "gluten_free"
    assert_includes resposta, "monday"
  end
end
