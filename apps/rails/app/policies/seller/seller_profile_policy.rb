# O painel do marmiteiro sobre o proprio perfil (`api/v1/seller/profile`).
#
# `show?` e `create?` valem para qualquer conta porque sao o caminho de
# cadastro: quem ainda nao tem perfil precisa poder perguntar (404 "crie um
# primeiro") e criar. Alterar e apagar exigem ser o dono.
module Seller
  class SellerProfilePolicy < ApplicationPolicy
    def show? = signed_in?
    def create? = signed_in?

    def update? = owns_record?
    def destroy? = owns_record?
  end
end
