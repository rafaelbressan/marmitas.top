require "test_helper"

# `auth/me` e `auth/logout` falam da propria sessao. `register` e `login` nao
# tem policy porque acontecem antes de existir usuario — sao as duas unicas
# acoes da API fora do `verify_authorized`.
class UserPolicyTest < ActiveSupport::TestCase
  test "me e logout: so a propria conta" do
    [ :me?, :logout? ].each do |action|
      assert_matrix UserPolicy, action, users(:carla),
        anonimo: false, consumidor: true, vendedor_dono: false,
        vendedor_outro: false, admin: false
    end
  end
end
