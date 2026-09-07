require "test_helper"

# O painel de moderacao inteiro cabe numa linha: e do admin, e de mais ninguem.
# Nem do marmiteiro avaliado — que teria o maior interesse em derrubar uma nota
# ruim sobre o proprio negocio.
class Admin::ReviewPolicyTest < ActiveSupport::TestCase
  setup { @review = reviews(:diego_sobre_jorge_em_moderacao) }

  test "moderar avaliacao: so admin, nas quatro acoes" do
    [ :index?, :show?, :approve?, :remove? ].each do |action|
      assert_matrix Admin::ReviewPolicy, action, @review,
        anonimo: false, consumidor: false, vendedor_dono: false,
        vendedor_outro: false, admin: true
    end
  end

  test "o marmiteiro avaliado nao aprova nem remove a avaliacao sobre si mesmo" do
    # `diego_sobre_jorge_em_moderacao` e sobre o Jorge, que aqui e o
    # `vendedor_outro`. Ele continua false nas quatro acoes acima; este teste
    # deixa o caso escrito com o nome certo.
    assert_not Admin::ReviewPolicy.new(users(:jorge), @review).remove?
    assert_not Admin::ReviewPolicy.new(users(:jorge), @review).approve?
  end
end
