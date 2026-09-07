require "test_helper"

class FavoritePolicyTest < ActiveSupport::TestCase
  setup { @favorito = favorites(:carla_segue_marli) }

  test "listar, criar e consultar favorito: qualquer conta" do
    [ :index?, :dishes?, :sellers?, :check?, :create?, :remove? ].each do |action|
      assert_matrix FavoritePolicy, action, Favorite,
        anonimo: false, consumidor: true, vendedor_dono: true,
        vendedor_outro: true, admin: true
    end
  end

  test "apagar favorito: so de quem e" do
    assert_matrix FavoritePolicy, :destroy?, @favorito,
      anonimo: false, consumidor: true, vendedor_dono: false,
      vendedor_outro: false, admin: false
  end
end
