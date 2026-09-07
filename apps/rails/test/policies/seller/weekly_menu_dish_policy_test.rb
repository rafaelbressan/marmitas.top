require "test_helper"

# Baixa de quantidade (BRES-128). Mexe no numero que o consumidor ve como
# "ainda tem": um marmiteiro que desse baixa no prato do outro zeraria o
# cardapio do concorrente.
class Seller::WeeklyMenuDishPolicyTest < ActiveSupport::TestCase
  test "dar baixa: so o dono do cardapio" do
    assert_matrix Seller::WeeklyMenuDishPolicy, :update?, weekly_menu_dishes(:marli_feijoada),
      anonimo: false, consumidor: false, vendedor_dono: true,
      vendedor_outro: false, admin: false
  end

  test "a linha do cardapio do vizinho e do vizinho" do
    assert_matrix Seller::WeeklyMenuDishPolicy, :update?, weekly_menu_dishes(:jorge_carne),
      anonimo: false, consumidor: false, vendedor_dono: false,
      vendedor_outro: true, admin: false
  end
end
