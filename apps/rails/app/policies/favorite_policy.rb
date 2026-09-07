# Favorito e da pessoa. As listagens ja saem de `current_user.favorites`, e a
# policy garante que apagar so vale para o registro proprio.
class FavoritePolicy < ApplicationPolicy
  def index? = signed_in?
  def dishes? = index?
  def sellers? = index?
  def check? = index?
  def create? = signed_in?

  def destroy? = authored_record?

  # `favorites#remove` apaga pelo par (tipo, id) em vez do id do favorito, e a
  # busca ja e feita dentro de `current_user.favorites`.
  def remove? = signed_in?
end
