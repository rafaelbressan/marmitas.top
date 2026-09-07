# O perfil descartado nao existe para a API.
#
# Depois de `DELETE /api/v1/seller/profile` o painel responde como se o
# marmiteiro ainda nao tivesse criado o perfil — senao ele continuaria criando
# prato e cardapio pendurados num perfil que a vitrine nao mostra mais.
# `POST /api/v1/seller/profile` traz tudo de volta (BRES-140).
module SellerProfileScope
  extend ActiveSupport::Concern

  included do
    before_action :require_seller_profile
  end

  private

  def seller_profile
    profile = current_user&.seller_profile

    profile unless profile&.discarded?
  end

  def require_seller_profile
    return if seller_profile

    render json: { error: "Seller profile required" }, status: :forbidden
  end
end
