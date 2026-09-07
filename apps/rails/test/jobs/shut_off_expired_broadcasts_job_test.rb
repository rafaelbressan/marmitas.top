require "test_helper"

# `SellerProfile#auto_shutoff_if_expired!` existia desde o inicio e nada no
# repositorio o chamava. Este job e quem chama.
class ShutOffExpiredBroadcastsJobTest < ActiveSupport::TestCase
  test "desliga o anuncio de quem passou do leaving_at" do
    tiao = seller_profiles(:tiao_vencido)
    assert tiao.currently_active, "a fixture tem que comecar ligada, como o bug"
    assert tiao.broadcast_expired?

    assert_equal 1, ShutOffExpiredBroadcastsJob.perform_now

    tiao.reload
    assert_not tiao.currently_active
    assert_nil tiao.current_location_id
    assert_nil tiao.leaving_at
  end

  test "nao encosta em quem ainda esta no prazo" do
    marli = seller_profiles(:marli_marmitas)

    ShutOffExpiredBroadcastsJob.perform_now

    marli.reload
    assert marli.currently_active
    assert_equal selling_locations(:largo_do_machado).id, marli.current_location_id
  end

  # Viajando no tempo em vez de esperar 12 horas: as 12 horas padrao do
  # DEFAULT_BROADCAST_DURATION passam e todo mundo cai.
  test "depois do prazo padrao todo anuncio aberto cai" do
    marli = seller_profiles(:marli_marmitas)
    neide = seller_profiles(:neide_ambulante)

    travel_to SellerProfile::DEFAULT_BROADCAST_DURATION.from_now + 1.minute do
      ShutOffExpiredBroadcastsJob.perform_now
    end

    assert_not marli.reload.currently_active
    assert_not neide.reload.currently_active
  end

  test "rodar duas vezes nao muda nada na segunda" do
    assert_equal 1, ShutOffExpiredBroadcastsJob.perform_now
    assert_equal 0, ShutOffExpiredBroadcastsJob.perform_now
  end

  test "o job esta registrado no config/recurring.yml" do
    recurring = YAML.safe_load(
      ERB.new(Rails.root.join("config/recurring.yml").read).result,
      aliases: true
    )

    entrada = recurring.dig("production", "shut_off_expired_broadcasts")

    assert_not_nil entrada, "o job nao esta em config/recurring.yml, entao ninguem o dispara"
    assert_equal "ShutOffExpiredBroadcastsJob", entrada["class"]
    assert_equal "every 5 minutes", entrada["schedule"]
  end
end
