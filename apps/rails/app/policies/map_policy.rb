# O mapa nao tem model: o registro autorizado e o simbolo `:map`.
#
# As duas acoes sao leitura publica de marmiteiro verificado e anunciando.
# Hoje so `map#sellers` esta no `skip_before_action :authenticate_user!`;
# `map#bounds` exige token por omissao, e isso e uma divergencia de rota, nao
# de policy.
class MapPolicy < ApplicationPolicy
  def sellers? = true
  def bounds? = true
end
