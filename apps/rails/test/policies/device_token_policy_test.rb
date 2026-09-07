require "test_helper"

# Token de aparelho e a chave que entrega push no celular da pessoa. Apagar o
# token de outro alguem e derrubar o aviso de "a marmiteira chegou" dela.
class DeviceTokenPolicyTest < ActiveSupport::TestCase
  setup { @token = device_tokens(:carla_iphone) }

  test "listar, registrar e desativar tokens: qualquer conta, para si" do
    [ :index?, :create?, :deactivate_all? ].each do |action|
      assert_matrix DeviceTokenPolicy, action, DeviceToken,
        anonimo: false, consumidor: true, vendedor_dono: true,
        vendedor_outro: true, admin: true
    end
  end

  test "apagar token: so o dono do aparelho" do
    assert_matrix DeviceTokenPolicy, :destroy?, @token,
      anonimo: false, consumidor: true, vendedor_dono: false,
      vendedor_outro: false, admin: false
  end
end
