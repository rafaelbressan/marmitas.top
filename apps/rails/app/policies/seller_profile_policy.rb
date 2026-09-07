# Vitrine publica do marmiteiro. Quem procura marmita nao precisa de conta:
# `sellers#index`, `#show` e `#nearby` respondem para anonimo.
#
# O que o dono faz com o proprio perfil esta em `Seller::SellerProfilePolicy`.
class SellerProfilePolicy < ApplicationPolicy
  def index? = true
  def show? = true
  def nearby? = true
end
