require "test_helper"

# Vitrine publica de cardapio. O que o dono ve do proprio cardapio esta em
# `Seller::WeeklyMenuPolicy`, que expoe `total_orders_count` e o texto de
# WhatsApp — e nao e publico.
class WeeklyMenuPolicyTest < ActiveSupport::TestCase
  test "ler cardapio e publico" do
    [ :index?, :available_today?, :seller_menus? ].each do |action|
      assert_matrix WeeklyMenuPolicy, action, WeeklyMenu,
        anonimo: true, consumidor: true, vendedor_dono: true,
        vendedor_outro: true, admin: true
    end

    assert_matrix WeeklyMenuPolicy, :show?, weekly_menus(:marli_semana_atual),
      anonimo: true, consumidor: true, vendedor_dono: true,
      vendedor_outro: true, admin: true
  end
end
