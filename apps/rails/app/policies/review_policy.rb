# Avaliacao tem quatro donos possiveis por acao: qualquer um le, quem tem conta
# escreve, so o autor edita, e ninguem marca a propria como util.
#
# As regras de janela de 48h e de moderacao continuam no model
# (`Review#editable_by?`, `#flaggable_by?`) — a policy chama, nao reescreve.
# Duas copias da mesma regra e como as duas fontes de `reviews_count`: uma
# delas fica errada e ninguem percebe. O `signed_in?` na frente existe porque
# esses metodos do model recebem `current_user` e estouram com `nil`.
class ReviewPolicy < ApplicationPolicy
  def index? = true
  def show? = true

  def create? = signed_in?

  def update? = signed_in? && record.editable_by?(user)
  def destroy? = update?

  def flag? = signed_in? && record.flaggable_by?(user)

  # Marcar como util e voto de terceiro: o autor nao vota em si mesmo.
  def helpful? = signed_in? && !authored_record?
end
