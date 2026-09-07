# Leitura publica de cardapio: `menus#index`, `#show`, `#available_today` e
# `sellers#menus`. Sao os cardapios que o app mostra antes do login.
#
# O que o dono faz com o proprio cardapio esta em `Seller::WeeklyMenuPolicy`,
# que expoe campos que a vitrine nao mostra (`total_orders_count`).
class WeeklyMenuPolicy < ApplicationPolicy
  def index? = true
  def show? = true
  def available_today? = true
  def seller_menus? = true
end
