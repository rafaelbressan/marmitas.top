# Prato do cardapio, pelo lado de quem cozinha.
#
# Listar e criar exigem perfil de marmiteiro; ler, alterar e apagar um prato
# especifico exigem ser dono dele. Um marmiteiro nao alcanca o prato do outro.
module Seller
  class DishPolicy < ApplicationPolicy
    def index? = seller?
    def create? = seller?

    # Estatistica de favoritos e faturamento indireto: quantas pessoas salvaram
    # cada prato. So do proprio negocio.
    def favorites_stats? = seller?

    def show? = owns_record?
    def update? = owns_record?
    def destroy? = owns_record?
  end
end
