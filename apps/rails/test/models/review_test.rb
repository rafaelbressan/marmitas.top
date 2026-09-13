require "test_helper"

# Regras de negocio que vivem so no model Review: janela de 48h para editar,
# uma avaliacao por marmiteiro por dia, proibicao de avaliar o proprio negocio,
# comentario obrigatorio em nota extrema e sinalizacao automatica de padrao
# suspeito. Fluxos de API (criar/editar/descartar avaliacao via HTTP) sao
# cobertos pelos testes de integracao; aqui e so o model.
class ReviewTest < ActiveSupport::TestCase
  # --- Janela de edicao de 48h -------------------------------------------

  test "editable_by? confere autor, janela de 48h e status de moderacao" do
    review = reviews(:diego_sobre_marli)

    assert review.editable_by?(users(:diego))
    assert_not review.editable_by?(users(:carla)) # nao e quem escreveu

    travel_to(review.created_at + 49.hours) do
      assert_not review.editable_by?(users(:diego)) # janela de 48h ja fechou
    end

    em_moderacao = reviews(:diego_sobre_jorge_em_moderacao)
    assert_not em_moderacao.editable_by?(users(:diego)) # sob moderacao trava edicao
  end

  test "dentro da janela de 48h a edicao e permitida" do
    review = reviews(:diego_sobre_marli)

    travel_to(review.created_at + 47.hours) do
      assert review.update(comment: "Editando dentro do prazo.")
    end

    assert_equal "Editando dentro do prazo.", review.reload.comment
  end

  test "apos 48h a edicao e bloqueada com a mensagem de prazo expirado" do
    review = reviews(:diego_sobre_marli)
    comentario_original = review.comment

    travel_to(review.created_at + 49.hours) do
      assert_not review.update(comment: "Tentando editar tarde demais.")
      assert_includes review.errors[:base],
                       "Esta avaliação não pode mais ser editada (prazo de 48h expirado)"
    end

    assert_equal comentario_original, review.reload.comment
  end

  # --- Uma avaliacao por usuario, por marmiteiro, por dia ------------------

  test "mesmo usuario nao pode avaliar o mesmo marmiteiro duas vezes no mesmo dia" do
    original = reviews(:diego_sobre_marli)

    duplicata = Review.new(
      user: users(:diego),
      seller_profile: seller_profiles(:marli_marmitas),
      encounter_date: original.encounter_date,
      rating: 3
    )

    assert_not duplicata.valid?
    assert_includes duplicata.errors[:user_id], "Você já avaliou este marmiteiro hoje"
  end

  test "mesmo usuario e mesmo marmiteiro em dia diferente e valido" do
    original = reviews(:diego_sobre_marli)

    outro_dia = Review.new(
      user: users(:diego),
      seller_profile: seller_profiles(:marli_marmitas),
      encounter_date: original.encounter_date - 10.days,
      rating: 3
    )

    assert outro_dia.valid?
  end

  test "mesmo usuario e mesmo dia mas marmiteiro diferente e valido" do
    original = reviews(:diego_sobre_marli)

    outro_marmiteiro = Review.new(
      user: users(:diego),
      seller_profile: seller_profiles(:jorge_quentinhas),
      encounter_date: original.encounter_date,
      rating: 3
    )

    assert outro_marmiteiro.valid?
  end

  # --- Nao pode avaliar o proprio negocio -----------------------------------

  test "marmiteiro nao pode avaliar o proprio negocio" do
    review = Review.new(
      user: users(:marli),
      seller_profile: seller_profiles(:marli_marmitas),
      encounter_date: Date.current,
      rating: 4,
      comment: "Nota alta pra mim mesma."
    )

    assert_not review.valid?
    assert_includes review.errors[:base], "Você não pode avaliar seu próprio negócio"
  end

  test "avaliar o negocio de outra pessoa nao dispara a regra de negocio proprio" do
    review = Review.new(
      user: users(:diego),
      seller_profile: seller_profiles(:marli_marmitas),
      encounter_date: 5.days.ago.to_date,
      rating: 4
    )

    assert review.valid?
  end

  # --- Comentario obrigatorio em nota extrema (1 ou 5) ----------------------

  test "nota 1 sem comentario e invalida" do
    review = Review.new(
      user: users(:carla),
      seller_profile: seller_profiles(:jorge_quentinhas),
      encounter_date: Date.current,
      rating: 1
    )

    assert_not review.valid?
    assert_includes review.errors[:comment], "can't be blank"
  end

  test "nota 5 sem comentario e invalida" do
    review = Review.new(
      user: users(:carla),
      seller_profile: seller_profiles(:jorge_quentinhas),
      encounter_date: Date.current,
      rating: 5
    )

    assert_not review.valid?
    assert_includes review.errors[:comment], "can't be blank"
  end

  test "nota neutra sem comentario e valida" do
    review = Review.new(
      user: users(:carla),
      seller_profile: seller_profiles(:jorge_quentinhas),
      encounter_date: Date.current,
      rating: 3
    )

    assert review.valid?
  end

  test "nota 1 com comentario e valida" do
    review = Review.new(
      user: users(:carla),
      seller_profile: seller_profiles(:jorge_quentinhas),
      encounter_date: Date.current,
      rating: 1,
      comment: "Nao gostei da comida."
    )

    assert review.valid?
  end

  # --- Sinalizacao automatica de padrao suspeito ----------------------------
  #
  # `detect_suspicious_patterns` roda em `before_create` e olha
  # `user.reviews.where("created_at > 7.days.ago")`, contando por `created_at`
  # (quando a linha foi criada), nao por `encounter_date`. Por isso os
  # `Review.create!` abaixo variam `encounter_date` so pra nao esbarrar na
  # regra de uma avaliacao por marmiteiro por dia — o que conta pro padrao
  # suspeito e a quantidade de linhas criadas nos ultimos 7 dias.

  test "terceira avaliacao de 1 estrela em 7 dias e sinalizada automaticamente" do
    autor = users(:carla) # ja tem 1 avaliacao (5 estrelas) na fixture, dentro da janela de 7 dias

    Review.create!(user: autor, seller_profile: seller_profiles(:jorge_quentinhas),
                   rating: 1, comment: "Muito ruim.", encounter_date: 2.days.ago.to_date)
    Review.create!(user: autor, seller_profile: seller_profiles(:ana_verdinha),
                   rating: 1, comment: "Decepcionante.", encounter_date: 1.day.ago.to_date)

    terceira = Review.create!(user: autor, seller_profile: seller_profiles(:neide_ambulante),
                               rating: 1, comment: "Nao vou voltar.", encounter_date: Date.current)

    assert_equal "under_review", terceira.moderation_status
    assert_equal "Auto-flagged: Padrão suspeito de avaliações negativas", terceira.flag_reason
  end

  test "com so uma avaliacao de 1 estrela anterior, a proxima nao e sinalizada" do
    autor = users(:carla)

    Review.create!(user: autor, seller_profile: seller_profiles(:jorge_quentinhas),
                   rating: 1, comment: "Ruim.", encounter_date: 1.day.ago.to_date)

    segunda = Review.create!(user: autor, seller_profile: seller_profiles(:ana_verdinha),
                              rating: 1, comment: "Nao gostei.", encounter_date: Date.current)

    assert_equal "published", segunda.moderation_status
    assert_nil segunda.flag_reason
  end

  test "decima avaliacao em 7 dias e sinalizada por volume, mesmo com nota neutra" do
    autor = users(:carla) # + 1 avaliacao da fixture = 9 antes da que dispara a regra
    sellers = [
      seller_profiles(:jorge_quentinhas),
      seller_profiles(:ana_verdinha),
      seller_profiles(:bia_novata),
      seller_profiles(:neide_ambulante),
      seller_profiles(:tiao_vencido)
    ]

    8.times do |i|
      Review.create!(user: autor, seller_profile: sellers[i % sellers.size],
                     rating: 3, encounter_date: (i + 10).days.ago.to_date)
    end

    decima = Review.create!(user: autor, seller_profile: seller_profiles(:marli_marmitas),
                             rating: 3, encounter_date: Date.current)

    assert_equal "under_review", decima.moderation_status
    assert_equal "Auto-flagged: Muitas avaliações em curto período", decima.flag_reason
  end

  test "com oito avaliacoes anteriores em 7 dias, a nona nao e sinalizada por volume" do
    autor = users(:carla) # + 1 avaliacao da fixture = 8 antes da que testamos
    sellers = [
      seller_profiles(:jorge_quentinhas),
      seller_profiles(:ana_verdinha),
      seller_profiles(:bia_novata),
      seller_profiles(:neide_ambulante),
      seller_profiles(:tiao_vencido)
    ]

    7.times do |i|
      Review.create!(user: autor, seller_profile: sellers[i % sellers.size],
                     rating: 3, encounter_date: (i + 10).days.ago.to_date)
    end

    nona = Review.create!(user: autor, seller_profile: seller_profiles(:marli_marmitas),
                           rating: 3, encounter_date: Date.current)

    assert_equal "published", nona.moderation_status
    assert_nil nona.flag_reason
  end
end
