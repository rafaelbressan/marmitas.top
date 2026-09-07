# Quem pode ver a posicao ao vivo de um ambulante.
#
# O pino de um ponto fixo e um endereco que o marmiteiro escolheu publicar. O
# pino "circulando" e a coordenada exata de uma pessoa na rua, regravada a cada
# poucos minutos. A BRES-113 decide o que um visitante sem token recebe; ate la
# a posicao ao vivo so sai para quem esta autenticado.
module LivePositionVisibility
  extend ActiveSupport::Concern

  private

  def live_position_visible?(location)
    return false if location.nil?

    location.ponto? || current_user.present?
  end
end
