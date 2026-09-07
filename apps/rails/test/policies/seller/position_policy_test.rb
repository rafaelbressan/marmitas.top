require "test_helper"

# Posicao ao vivo do ambulante (BRES-128). Quem nao cozinha nao transmite
# posicao — e ninguem transmite pela conta do outro, porque o controller grava
# em `current_user.seller_profile`.
class Seller::PositionPolicyTest < ActiveSupport::TestCase
  test "ler e gravar a propria posicao: so quem tem perfil de marmiteiro" do
    [ :show?, :update? ].each do |action|
      assert_matrix Seller::PositionPolicy, action, :position,
        anonimo: false, consumidor: false, vendedor_dono: true,
        vendedor_outro: true, admin: false
    end
  end
end
