require "test_helper"

# Este teste existe para provar o ambiente, nao para cobrir regra de negocio:
# se ele passa, as fixtures carregaram e o PostGIS esta funcionando no banco de
# teste — inclusive nos bancos paralelos que o `parallelize` cria.
class SellerProfileTest < ActiveSupport::TestCase
  # Largo do Machado, onde a Dona Marli esta anunciando.
  CATETE = { latitude: -22.929500, longitude: -43.177400 }.freeze

  test "as fixtures de ponto de venda chegam ao banco com a coluna geography preenchida" do
    assert_equal 7, SellingLocation.count
    assert_equal 7, SellingLocation.where.not(lonlat: nil).count
  end

  test "nearby encontra o marmiteiro que esta anunciando por perto" do
    encontrados = SellerProfile.nearby(CATETE[:latitude], CATETE[:longitude], 5)

    # A Marli esta num ponto fixo, a Neide circulando e o Paulo nunca foi
    # verificado (BRES-129): as tres dizem a mesma frase, "estou aberta", e as
    # tres tem que sair na mesma consulta PostGIS, por distancia.
    assert_equal [ seller_profiles(:marli_marmitas), seller_profiles(:neide_ambulante), seller_profiles(:paulo_novo) ],
                 encontrados.to_a
  end

  test "nearby calcula a distancia em quilometros a partir do ponto buscado" do
    # ~1 km ao sul do Largo do Machado.
    marli = SellerProfile.nearby(-22.938500, -43.177400, 5).first

    assert_in_delta 1.0, marli.distance_km, 0.2
  end

  test "nearby ignora quem tem ponto de venda perto mas nao esta anunciando" do
    jorge = seller_profiles(:jorge_quentinhas)

    assert_not jorge.currently_active
    assert_operator selling_locations(:rua_do_catete).seller_profile, :==, jorge
    assert_not_includes SellerProfile.nearby(CATETE[:latitude], CATETE[:longitude], 5), jorge
  end

  test "nearby respeita o raio: Sao Paulo nao aparece numa busca no Rio" do
    ana = seller_profiles(:ana_verdinha)

    assert ana.currently_active
    assert_not_includes SellerProfile.nearby(CATETE[:latitude], CATETE[:longitude], 5), ana
    assert_includes SellerProfile.nearby(-23.560500, -46.685500, 5), ana
  end
end
