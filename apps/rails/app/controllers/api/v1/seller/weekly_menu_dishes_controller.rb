module Api
  module V1
    module Seller
      # Baixa de quantidade — a acao mais frequente do dia do marmiteiro.
      #
      # Duas frases distintas, um endpoint so, cada uma com o seu parametro:
      #
      #   { "sold": 3 }                -> saiu 3 agora        (decremento relativo)
      #   { "remaining_quantity": 5 }  -> sobraram 5          (ajuste absoluto)
      #   { "remaining_quantity": 0 }  -> acabou
      #
      # Os dois parametros sao mutuamente exclusivos: mandar os dois, ou nenhum,
      # e erro. "Vendi 3" e "sobraram 3" sao coisas diferentes e o servidor nao
      # adivinha qual delas o app quis dizer.
      class WeeklyMenuDishesController < BaseController
        include SellerProfileScope

        before_action :set_menu_dish

        # PATCH /api/v1/seller/weekly_menus/:id/dishes/:dish_id/quantity
        def update
          authorize [ :seller, @menu_dish ], :update?

          sold = params[:sold]
          remaining = params[:remaining_quantity]

          if sold.present? == remaining.present?
            return render json: {
              error: "Informe 'sold' (quanto saiu) ou 'remaining_quantity' (quanto sobrou), nunca os dois."
            }, status: :unprocessable_entity
          end

          sold.present? ? apply_sale(sold) : apply_absolute(remaining)
        end

        private

        def apply_sale(sold)
          amount = Integer(sold)
          return render_invalid_amount unless amount.positive?

          if @menu_dish.sell!(amount)
            render_dish("Baixa registrada")
          else
            render json: {
              error: "Estoque insuficiente: restam #{@menu_dish.remaining_quantity}.",
              remaining_quantity: @menu_dish.remaining_quantity
            }, status: :unprocessable_entity
          end
        rescue ArgumentError, TypeError
          render_invalid_amount
        end

        def apply_absolute(remaining)
          quantity = Integer(remaining)
          @menu_dish.set_remaining!(quantity)
          render_dish(quantity.zero? ? "Prato marcado como esgotado" : "Quantidade atualizada")
        rescue ArgumentError, TypeError
          render_invalid_amount
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
        end

        def render_invalid_amount
          render json: { error: "Quantidade inválida" }, status: :unprocessable_entity
        end

        def render_dish(message)
          render json: {
            message: message,
            dish: {
              dish_id: @menu_dish.dish_id,
              dish_name: @menu_dish.dish.name,
              available_quantity: @menu_dish.available_quantity,
              remaining_quantity: @menu_dish.remaining_quantity,
              is_available: @menu_dish.available?
            }
          }, status: :ok
        end

        # So o dono do cardapio baixa: o cardapio e procurado dentro do perfil de
        # quem esta autenticado, entao o cardapio de outro marmiteiro simplesmente
        # nao existe aqui.
        def set_menu_dish
          menu = seller_profile.weekly_menus.kept.find(params[:id])
          @menu_dish = menu.weekly_menu_dishes.kept.find_by(dish_id: params[:dish_id])

          render json: { error: "Dish not in menu" }, status: :not_found if @menu_dish.nil?
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Menu not found" }, status: :not_found
        end
      end
    end
  end
end
