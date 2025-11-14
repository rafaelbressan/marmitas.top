module Api
  module V1
    module Seller
      class DishesController < BaseController
        before_action :set_dish, only: [:show, :update, :destroy]

        # GET /api/v1/seller/dishes
        def index
          @dishes = current_user.seller_profile.dishes.order(created_at: :desc)
          @dishes = @dishes.active if params[:active_only] == 'true'

          render json: {
            dishes: @dishes.map { |dish| dish_response(dish) }
          }, status: :ok
        end

        # GET /api/v1/seller/dishes/favorites_stats
        def favorites_stats
          @dishes = current_user.seller_profile.dishes
                                .order(favorites_count: :desc)
                                .limit(params[:limit] || 10)

          total_favorites = current_user.seller_profile.dishes.sum(:favorites_count)

          render json: {
            total_favorites: total_favorites,
            top_dishes: @dishes.map { |dish|
              {
                id: dish.id,
                name: dish.name,
                favorites_count: dish.favorites_count,
                base_price: dish.base_price.to_f,
                active: dish.active,
                percentage: total_favorites > 0 ? ((dish.favorites_count.to_f / total_favorites) * 100).round(2) : 0
              }
            }
          }, status: :ok
        end

        # GET /api/v1/seller/dishes/:id
        def show
          render json: { dish: dish_response(@dish) }, status: :ok
        end

        # POST /api/v1/seller/dishes
        def create
          unless current_user.seller_profile
            return render json: { error: 'Seller profile required' }, status: :forbidden
          end

          @dish = current_user.seller_profile.dishes.build(dish_params)

          if @dish.save
            attach_photos if params[:dish][:photos].present?
            render json: {
              message: 'Dish created successfully',
              dish: dish_response(@dish)
            }, status: :created
          else
            render json: { errors: @dish.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/seller/dishes/:id
        def update
          if @dish.update(dish_params)
            attach_photos if params[:dish][:photos].present?
            render json: {
              message: 'Dish updated successfully',
              dish: dish_response(@dish)
            }, status: :ok
          else
            render json: { errors: @dish.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/seller/dishes/:id
        def destroy
          # Check if dish is in any active menus
          if @dish.weekly_menus.active.available_now.any?
            return render json: {
              error: 'Cannot delete dish that is in active menus'
            }, status: :unprocessable_entity
          end

          @dish.destroy
          render json: { message: 'Dish deleted successfully' }, status: :ok
        end

        private

        def set_dish
          @dish = current_user.seller_profile.dishes.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Dish not found' }, status: :not_found
        end

        def dish_params
          params.require(:dish).permit(
            :name,
            :description,
            :base_price,
            :active,
            dietary_tags: []
          )
        end

        def attach_photos
          photos = params[:dish][:photos]
          photos = [photos] unless photos.is_a?(Array)
          photos.each do |photo|
            @dish.photos.attach(photo) if photo.present?
          end
        end

        def dish_response(dish)
          {
            id: dish.id,
            name: dish.name,
            description: dish.description,
            base_price: dish.base_price.to_f,
            dietary_tags: dish.dietary_tags,
            dietary_tags_display: dish.dietary_tags_display,
            active: dish.active,
            favorites_count: dish.favorites_count,
            photos: dish.photos.attached? ? dish.photos.map { |photo| rails_blob_url(photo) } : [],
            created_at: dish.created_at,
            updated_at: dish.updated_at
          }
        end
      end
    end
  end
end
