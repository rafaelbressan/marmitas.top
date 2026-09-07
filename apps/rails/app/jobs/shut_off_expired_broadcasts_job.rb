# Desliga o anuncio de quem passou do `leaving_at`.
#
# `SellerProfile#auto_shutoff_if_expired!` existia desde o inicio e nada no
# repositorio o chamava: quem esquecia de tocar "sai daqui" ficava no mapa a
# noite inteira. Este job e a primeira ponta da correcao; a segunda e o escopo
# `SellerProfile.broadcasting`, que filtra o vencido na leitura mesmo que este
# job esteja atrasado ou parado.
class ShutOffExpiredBroadcastsJob < ApplicationJob
  queue_as :default

  def perform
    shut_off = 0

    SellerProfile.with_expired_broadcast.find_each do |seller_profile|
      shut_off += 1 if seller_profile.auto_shutoff_if_expired!
    end

    Rails.logger.info("ShutOffExpiredBroadcastsJob: #{shut_off} anuncio(s) vencido(s) desligado(s)")
    shut_off
  end
end
