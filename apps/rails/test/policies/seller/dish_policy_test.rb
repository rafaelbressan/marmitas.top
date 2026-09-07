require "test_helper"

# Prato pelo lado de quem cozinha. A linha que mais importa e a ultima: o
# marmiteiro do lado nao alcanca o prato do vizinho.
class Seller::DishPolicyTest < ActiveSupport::TestCase
  setup { @dish = dishes(:feijoada) } # da Marli

  test "listar e criar prato: qualquer marmiteiro com perfil, ninguem mais" do
    [ :index?, :create?, :favorites_stats? ].each do |action|
      assert_matrix Seller::DishPolicy, action, Dish,
        anonimo: false, consumidor: false, vendedor_dono: true,
        vendedor_outro: true, admin: false
    end
  end

  test "ler, alterar e apagar um prato: so o dono — nem o outro marmiteiro, nem o admin" do
    [ :show?, :update?, :destroy? ].each do |action|
      assert_matrix Seller::DishPolicy, action, @dish,
        anonimo: false, consumidor: false, vendedor_dono: true,
        vendedor_outro: false, admin: false
    end
  end

  test "o prato do vizinho tambem nao e do dono" do
    assert_matrix Seller::DishPolicy, :update?, dishes(:carne_de_panela),
      anonimo: false, consumidor: false, vendedor_dono: false,
      vendedor_outro: true, admin: false
  end
end
