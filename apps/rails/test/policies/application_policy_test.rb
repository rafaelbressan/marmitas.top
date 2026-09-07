require "test_helper"

# A base nega tudo. Uma policy nova que esqueca de responder uma acao herda o
# "nao", nunca o "sim".
class ApplicationPolicyTest < ActiveSupport::TestCase
  test "toda acao nasce negada, para todos os papeis" do
    [ :index?, :show?, :create?, :new?, :update?, :edit?, :destroy? ].each do |action|
      assert_matrix ApplicationPolicy, action, dishes(:feijoada),
        anonimo: false, consumidor: false, vendedor_dono: false,
        vendedor_outro: false, admin: false
    end
  end

  # `owns_record?` fecha por falta de resposta: registro que nao sabe dizer de
  # que marmiteiro e nao pertence a ninguem.
  test "registro que nao responde seller_profile nao e de ninguem" do
    orfao = Struct.new(:id).new(1)
    policy = Seller::DishPolicy.new(users(:marli), orfao)

    assert_not policy.update?
  end
end
