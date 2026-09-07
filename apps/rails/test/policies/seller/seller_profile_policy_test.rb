require "test_helper"

class Seller::SellerProfilePolicyTest < ActiveSupport::TestCase
  setup { @profile = seller_profiles(:marli_marmitas) }

  # `show?` e `create?` sao o caminho de cadastro: quem ainda nao e marmiteiro
  # precisa poder perguntar pelo proprio perfil (404 "crie um primeiro") e
  # criar um. Sem isso o app nao tem como abrir a tela de virar marmiteiro.
  test "consultar e criar o proprio perfil: qualquer conta, menos anonimo" do
    [ :show?, :create? ].each do |action|
      assert_matrix Seller::SellerProfilePolicy, action, SellerProfile,
        anonimo: false, consumidor: true, vendedor_dono: true,
        vendedor_outro: true, admin: true
    end
  end

  test "alterar e apagar perfil: so o dono" do
    [ :update?, :destroy? ].each do |action|
      assert_matrix Seller::SellerProfilePolicy, action, @profile,
        anonimo: false, consumidor: false, vendedor_dono: true,
        vendedor_outro: false, admin: false
    end
  end
end
