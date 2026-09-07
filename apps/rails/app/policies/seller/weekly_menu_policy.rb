# Cardapio pelo lado de quem publica. Diferente de `WeeklyMenuPolicy`, que e a
# vitrine publica: aqui aparecem `total_orders_count` e o texto de WhatsApp.
module Seller
  class WeeklyMenuPolicy < ApplicationPolicy
    def index? = seller?
    def create? = seller?

    def show? = owns_record?
    def update? = owns_record?
    def destroy? = owns_record?

    def add_dish? = owns_record?
    def remove_dish? = owns_record?
    def duplicate? = owns_record?

    # O texto do WhatsApp lista pratos, precos e quantidade restante do
    # cardapio inteiro. E material do dono, nao da vitrine.
    def whatsapp_text? = owns_record?
  end
end
