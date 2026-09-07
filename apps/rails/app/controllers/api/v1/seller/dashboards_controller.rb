module Api
  module V1
    module Seller
      # Resumo do dia da tela "Minha loja".
      #
      # Junta o que ja e medido hoje — seguidores, nota e avaliacoes, pratos mais
      # favoritados e o cardapio que esta no ar — num payload so, para a tela nao
      # precisar de quatro chamadas.
      #
      # Nao ha nenhum numero de visualizacao aqui: o produto nao mede quem viu o
      # marmiteiro, e medir isso custaria uma escrita no endpoint publico mais
      # chamado da API. Ver BRES-132.
      class DashboardsController < BaseController
        RECENT_REVIEWS_LIMIT = 5
        TOP_DISHES_LIMIT = 5

        # GET /api/v1/seller/dashboard
        def show
          profile = current_user.seller_profile

          unless profile
            return render json: {
              error: "Você precisa criar um perfil de marmiteiro antes de ver o painel."
            }, status: :forbidden
          end

          render json: {
            dashboard: {
              profile: profile_summary(profile),
              rating: rating_summary(profile),
              recent_reviews: recent_reviews(profile),
              top_dishes: top_dishes(profile),
              today: today_summary(profile)
            }
          }, status: :ok
        end

        private

        def profile_summary(profile)
          location = profile.current_location

          {
            id: profile.id,
            business_name: profile.business_name,
            verified: profile.verified,
            currently_active: profile.currently_active,
            followers_count: profile.followers_count,
            last_active_at: profile.last_active_at,
            arrived_at: profile.arrived_at,
            leaving_at: profile.leaving_at,
            current_location: location && {
              id: location.id,
              name: location.name,
              address: location.address
            }
          }
        end

        # `display` diz se a tela pode mostrar a nota: abaixo de 5 avaliacoes o
        # `average_rating` gravado e 0.0 e nao significa "nota zero".
        #
        # De proposito sem `SellerProfile#rating_display`: aquele metodo pluraliza
        # "avaliacao" com o inflector ingles e devolve "2 avaliaçãos". Bug fora do
        # escopo desta issue — a tela monta o texto a partir destes campos.
        def rating_summary(profile)
          {
            display: profile.display_rating?,
            average: profile.average_rating.to_f,
            reviews_count: profile.reviews_count,
            distribution: profile.rating_distribution,
            trend: profile.rating_trend
          }
        end

        # `weekly_menu: :dishes` porque `display_dish_name` cai no cardapio quando
        # a avaliacao nao guardou o nome do prato.
        def recent_reviews(profile)
          reviews = profile.reviews.published
                           .includes(:user, weekly_menu: :dishes)
                           .order(created_at: :desc)
                           .limit(RECENT_REVIEWS_LIMIT)

          reviews.map do |review|
            {
              id: review.id,
              rating: review.rating,
              comment: review.comment,
              dish_name: review.display_dish_name,
              author_name: review.user.name,
              verified_encounter: review.verified_encounter,
              helpful_count: review.helpful_count,
              encounter_date: review.encounter_date,
              created_at: review.created_at
            }
          end
        end

        # Mesmo ranking de GET /api/v1/seller/dishes/favorites_stats, cortado no
        # que cabe na tela.
        def top_dishes(profile)
          total_favorites = profile.dishes.sum(:favorites_count)
          dishes = profile.dishes.order(favorites_count: :desc, name: :asc).limit(TOP_DISHES_LIMIT)

          {
            total_favorites: total_favorites,
            dishes: dishes.map do |dish|
              {
                id: dish.id,
                name: dish.name,
                active: dish.active,
                base_price: dish.base_price.to_f,
                favorites_count: dish.favorites_count,
                percentage: total_favorites.zero? ? 0.0 : ((dish.favorites_count.to_f / total_favorites) * 100).round(2)
              }
            end
          }
        end

        # "Vendeu 18 de 20" e subtracao: `available_quantity - remaining_quantity`.
        # Sem cardapio no ar os totais sao zero de verdade — nada foi anunciado.
        def today_summary(profile)
          menu = profile.weekly_menus.available_now.first

          return { menu: nil, announced_quantity: 0, remaining_quantity: 0, sold_quantity: 0, dishes: [] } unless menu

          menu_dishes = menu.weekly_menu_dishes.ordered.includes(:dish).to_a
          announced = menu_dishes.sum(&:available_quantity)
          remaining = menu_dishes.sum(&:remaining_quantity)

          {
            menu: {
              id: menu.id,
              title: menu.title,
              available_from: menu.available_from,
              available_until: menu.available_until
            },
            announced_quantity: announced,
            remaining_quantity: remaining,
            sold_quantity: announced - remaining,
            dishes: menu_dishes.map do |menu_dish|
              {
                id: menu_dish.id,
                dish_id: menu_dish.dish_id,
                name: menu_dish.dish.name,
                price: menu_dish.effective_price.to_f,
                available_quantity: menu_dish.available_quantity,
                remaining_quantity: menu_dish.remaining_quantity,
                sold_quantity: menu_dish.available_quantity - menu_dish.remaining_quantity
              }
            end
          }
        end
      end
    end
  end
end
