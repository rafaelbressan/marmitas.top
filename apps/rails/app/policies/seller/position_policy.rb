# Posicao ao vivo do ambulante (BRES-128). Nao tem model proprio — a posicao e
# gravada numa linha `circulando` de `selling_locations` — entao o registro
# autorizado e o simbolo `:position`.
#
# As duas acoes leem e escrevem `current_user.seller_profile`, so quem tem
# perfil de marmiteiro entra e cada um mexe na propria posicao.
module Seller
  class PositionPolicy < ApplicationPolicy
    def show? = seller?
    def update? = seller?
  end
end
