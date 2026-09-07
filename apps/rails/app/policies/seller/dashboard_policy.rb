# Resumo do dia da tela "Minha loja" (BRES-132). Nao tem model proprio: o
# registro autorizado e o simbolo `:dashboard`.
#
# O painel junta seguidores, nota, avaliacoes recentes, pratos mais favoritados
# e quanto saiu do cardapio de hoje. E o retrato do negocio de uma pessoa —
# so quem tem perfil de marmiteiro entra, e cada um ve o proprio, porque o
# controller monta tudo a partir de `current_user.seller_profile`.
module Seller
  class DashboardPolicy < ApplicationPolicy
    def show? = seller?
  end
end
