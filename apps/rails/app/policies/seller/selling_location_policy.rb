# Ponto de venda: onde o marmiteiro para e a que horas. `arrive` e `leave`
# ligam e desligam o anuncio de presenca, que e o recurso central do produto —
# se outro marmiteiro alcancasse isso, apagaria ou moveria o ponto alheio.
module Seller
  class SellingLocationPolicy < ApplicationPolicy
    def index? = seller?
    def create? = seller?

    def show? = owns_record?
    def update? = owns_record?
    def destroy? = owns_record?

    def arrive? = owns_record?
    def leave? = owns_record?
  end
end
