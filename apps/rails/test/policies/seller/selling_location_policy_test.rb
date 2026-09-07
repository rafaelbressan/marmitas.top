require "test_helper"

# Ponto de venda e o recurso central do produto: `arrive` e `leave` ligam e
# desligam o anuncio de presenca que o mapa mostra.
class Seller::SellingLocationPolicyTest < ActiveSupport::TestCase
  setup { @location = selling_locations(:largo_do_machado) } # da Marli

  test "listar e criar ponto de venda: qualquer marmiteiro com perfil" do
    [ :index?, :create? ].each do |action|
      assert_matrix Seller::SellingLocationPolicy, action, SellingLocation,
        anonimo: false, consumidor: false, vendedor_dono: true,
        vendedor_outro: true, admin: false
    end
  end

  test "ninguem chega, sai ou apaga o ponto de venda do outro" do
    [ :show?, :update?, :destroy?, :arrive?, :leave? ].each do |action|
      assert_matrix Seller::SellingLocationPolicy, action, @location,
        anonimo: false, consumidor: false, vendedor_dono: true,
        vendedor_outro: false, admin: false
    end
  end

  test "anunciar presenca no ponto do vizinho nao vale nem para quem tem perfil" do
    assert_matrix Seller::SellingLocationPolicy, :arrive?, selling_locations(:rua_do_catete),
      anonimo: false, consumidor: false, vendedor_dono: false,
      vendedor_outro: true, admin: false
  end
end
