require "test_helper"

# As preferencias moram no proprio usuario, entao o registro autorizado e o
# `User`. Ninguem escolhe o que o outro recebe — nem o admin.
class NotificationPreferencesPolicyTest < ActiveSupport::TestCase
  test "ver e mudar preferencia de aviso: so a propria conta" do
    [ :show?, :update? ].each do |action|
      assert_matrix NotificationPreferencesPolicy, action, users(:carla),
        anonimo: false, consumidor: true, vendedor_dono: false,
        vendedor_outro: false, admin: false
    end
  end
end
