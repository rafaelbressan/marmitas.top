require "test_helper"

# O painel "Minha loja" (BRES-132) e o retrato do negocio de uma pessoa. Quem
# nao cozinha nao entra — nem o admin, que nao tem perfil de marmiteiro.
class Seller::DashboardPolicyTest < ActiveSupport::TestCase
  test "ver o resumo do dia: so quem tem perfil de marmiteiro" do
    assert_matrix Seller::DashboardPolicy, :show?, :dashboard,
      anonimo: false, consumidor: false, vendedor_dono: true,
      vendedor_outro: true, admin: false
  end
end
