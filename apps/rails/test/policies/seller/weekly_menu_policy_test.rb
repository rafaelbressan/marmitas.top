require "test_helper"

class Seller::WeeklyMenuPolicyTest < ActiveSupport::TestCase
  setup { @menu = weekly_menus(:marli_semana_atual) }

  test "listar e criar cardapio: qualquer marmiteiro com perfil" do
    [ :index?, :create? ].each do |action|
      assert_matrix Seller::WeeklyMenuPolicy, action, WeeklyMenu,
        anonimo: false, consumidor: false, vendedor_dono: true,
        vendedor_outro: true, admin: false
    end
  end

  test "mexer no cardapio do outro nao acontece por nenhuma das sete acoes" do
    [ :show?, :update?, :destroy?, :add_dish?, :remove_dish?, :duplicate?, :whatsapp_text? ].each do |action|
      assert_matrix Seller::WeeklyMenuPolicy, action, @menu,
        anonimo: false, consumidor: false, vendedor_dono: true,
        vendedor_outro: false, admin: false
    end
  end

  test "o texto de WhatsApp do cardapio do vizinho nao sai para o dono daqui" do
    assert_matrix Seller::WeeklyMenuPolicy, :whatsapp_text?, weekly_menus(:jorge_semana_atual),
      anonimo: false, consumidor: false, vendedor_dono: false,
      vendedor_outro: true, admin: false
  end
end
