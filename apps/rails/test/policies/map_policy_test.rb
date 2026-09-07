require "test_helper"

class MapPolicyTest < ActiveSupport::TestCase
  # As duas acoes sao leitura publica. A diferenca de hoje — `map#sellers`
  # responde sem token e `map#bounds` exige um — esta no
  # `skip_before_action :authenticate_user!` do controller, nao aqui.
  test "o mapa e publico nas duas acoes" do
    [ :sellers?, :bounds? ].each do |action|
      assert_matrix MapPolicy, action, :map,
        anonimo: true, consumidor: true, vendedor_dono: true,
        vendedor_outro: true, admin: true
    end
  end
end
