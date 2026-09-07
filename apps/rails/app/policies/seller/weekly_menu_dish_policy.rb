# Baixa de quantidade (BRES-128): "vendi 3" / "sobraram 5". E a acao mais
# frequente do dia, e mexe no numero que o consumidor ve como "ainda tem".
#
# `WeeklyMenuDish` responde `seller_profile` pelo cardapio (delegate no model),
# entao `owns_record?` fecha sozinho: um marmiteiro nao da baixa no prato do
# outro.
module Seller
  class WeeklyMenuDishPolicy < ApplicationPolicy
    def update? = owns_record?
  end
end
