# Vitrine publica do marmiteiro. Quem procura marmita nao precisa de conta:
# `sellers#index`, `#show` e `#nearby` respondem para anonimo.
#
# O que o dono faz com o proprio perfil esta em `Seller::SellerProfilePolicy`.
class SellerProfilePolicy < ApplicationPolicy
  def index? = true
  def show? = true
  def nearby? = true

  # Telefone e whatsapp sao contato direto com uma pessoa fisica. So sai para
  # quem esta com token — sem isso, `GET /api/v1/sellers/:id` vazava o
  # telefone de qualquer id, sem autenticacao (BRES-136).
  def contact_visible? = signed_in?

  # Coordenada exata e o endereco de texto livre (que para quem vende de casa
  # e o proprio endereco residencial) so saem para quem esta autenticado. Sem
  # token o publico ve so o nome do ponto atual — nao existe ainda um campo de
  # bairro para reduzir para essa precisao (falta documentada em
  # docs/SITE.md §7.2).
  def precise_location_visible? = signed_in?
end
