require "test_helper"

# Vitrine publica. Quem procura marmita nao precisa de conta.
class SellerProfilePolicyTest < ActiveSupport::TestCase
  test "navegar marmiteiros e publico" do
    [ :index?, :nearby? ].each do |action|
      assert_matrix SellerProfilePolicy, action, SellerProfile,
        anonimo: true, consumidor: true, vendedor_dono: true,
        vendedor_outro: true, admin: true
    end

    assert_matrix SellerProfilePolicy, :show?, seller_profiles(:marli_marmitas),
      anonimo: true, consumidor: true, vendedor_dono: true,
      vendedor_outro: true, admin: true
  end

  # `sellers#index`, `#nearby` e o mapa filtram por `verified`; `#show` busca
  # por id sem filtro. A policy nao muda isso — esta escrito aqui para o dia em
  # que a decisao for outra.
  test "perfil nao verificado tambem responde por id" do
    assert_matrix SellerProfilePolicy, :show?, seller_profiles(:jorge_quentinhas),
      anonimo: true, consumidor: true, vendedor_dono: true,
      vendedor_outro: true, admin: true
  end
end
