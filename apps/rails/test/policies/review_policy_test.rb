require "test_helper"

# Avaliacao muda de dono a cada acao: qualquer um le, quem tem conta escreve,
# so quem escreveu edita, e ninguem marca a propria como util.
class ReviewPolicyTest < ActiveSupport::TestCase
  setup do
    @da_carla = reviews(:carla_sobre_marli)      # autora: consumidor
    @do_diego = reviews(:diego_sobre_marli)      # autor: ninguem da matriz
  end

  test "ler avaliacao e publico" do
    [ :index?, :show? ].each do |action|
      assert_matrix ReviewPolicy, action, @da_carla,
        anonimo: true, consumidor: true, vendedor_dono: true,
        vendedor_outro: true, admin: true
    end
  end

  test "escrever avaliacao exige conta" do
    assert_matrix ReviewPolicy, :create?, Review,
      anonimo: false, consumidor: true, vendedor_dono: true,
      vendedor_outro: true, admin: true
  end

  test "editar e apagar avaliacao: so quem escreveu — nem o marmiteiro avaliado, nem o admin" do
    [ :update?, :destroy? ].each do |action|
      assert_matrix ReviewPolicy, action, @da_carla,
        anonimo: false, consumidor: true, vendedor_dono: false,
        vendedor_outro: false, admin: false
    end
  end

  # A linha acima diz "consumidor: true" porque a Carla escreveu aquela
  # avaliacao. Se o `true` viesse de "estar logado" e nao de "ser a autora",
  # esta tabela seria igual — e ela nao e.
  test "estar logado nao edita a avaliacao dos outros" do
    [ :update?, :destroy? ].each do |action|
      assert_matrix ReviewPolicy, action, @do_diego,
        anonimo: false, consumidor: false, vendedor_dono: false,
        vendedor_outro: false, admin: false
    end
  end

  test "a janela de 48h fecha a edicao ate para a autora" do
    @da_carla.update_column(:created_at, 3.days.ago)

    assert_matrix ReviewPolicy, :update?, @da_carla.reload,
      anonimo: false, consumidor: false, vendedor_dono: false,
      vendedor_outro: false, admin: false
  end

  test "avaliacao sob moderacao nao e editada por ninguem" do
    @da_carla.update_column(:moderation_status, "under_review")

    assert_matrix ReviewPolicy, :update?, @da_carla.reload,
      anonimo: false, consumidor: false, vendedor_dono: false,
      vendedor_outro: false, admin: false
  end

  test "denunciar avaliacao: qualquer conta menos a de quem escreveu" do
    assert_matrix ReviewPolicy, :flag?, @da_carla,
      anonimo: false, consumidor: false, vendedor_dono: true,
      vendedor_outro: true, admin: true
  end

  test "avaliacao ja denunciada nao e denunciada de novo" do
    assert_matrix ReviewPolicy, :flag?, reviews(:diego_sobre_jorge_em_moderacao),
      anonimo: false, consumidor: false, vendedor_dono: false,
      vendedor_outro: false, admin: false
  end

  test "marcar como util: qualquer conta menos a de quem escreveu" do
    assert_matrix ReviewPolicy, :helpful?, @da_carla,
      anonimo: false, consumidor: false, vendedor_dono: true,
      vendedor_outro: true, admin: true
  end
end
