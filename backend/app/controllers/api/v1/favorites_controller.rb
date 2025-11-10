module Api
  module V1
    class FavoritesController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/favorites
      def index
        @favorites = current_user.favorites.includes(:favoritable).order(created_at: :desc)

        render json: {
          favorites: @favorites.map { |fav| favorite_response(fav) },
          dishes: current_user.favorited_dishes.includes(:seller_profile).map { |dish| dish_favorite_response(dish) },
          sellers: current_user.favorited_sellers.includes(:user).map { |seller| seller_favorite_response(seller) }
        }, status: :ok
      end

      # GET /api/v1/favorites/dishes
      def dishes
        @dishes = current_user.favorited_dishes.includes(:seller_profile, photos_attachments: :blob).order('favorites.created_at DESC')

        render json: {
          dishes: @dishes.map { |dish| dish_favorite_response(dish) }
        }, status: :ok
      end

      # GET /api/v1/favorites/sellers
      def sellers
        @sellers = current_user.favorited_sellers.includes(:user).order('favorites.created_at DESC')

        render json: {
          sellers: @sellers.map { |seller| seller_favorite_response(seller) }
        }, status: :ok
      end

      # POST /api/v1/favorites
      def create
        favoritable = find_favoritable

        unless favoritable
          return render json: { error: 'Invalid favoritable type or ID' }, status: :unprocessable_entity
        end

        begin
          @favorite = current_user.favorite!(favoritable)

          render json: {
            message: 'Added to favorites successfully',
            favorite: favorite_response(@favorite)
          }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/favorites/:id
      def destroy
        @favorite = current_user.favorites.find(params[:id])
        @favorite.destroy

        render json: { message: 'Removed from favorites successfully' }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Favorite not found' }, status: :not_found
      end

      # DELETE /api/v1/favorites/remove
      def remove
        favoritable = find_favoritable

        unless favoritable
          return render json: { error: 'Invalid favoritable type or ID' }, status: :unprocessable_entity
        end

        if current_user.unfavorite!(favoritable)
          render json: { message: 'Removed from favorites successfully' }, status: :ok
        else
          render json: { error: 'Item was not favorited' }, status: :not_found
        end
      end

      # GET /api/v1/favorites/check
      def check
        favoritable = find_favoritable

        unless favoritable
          return render json: { error: 'Invalid favoritable type or ID' }, status: :unprocessable_entity
        end

        is_favorited = current_user.favorited?(favoritable)

        render json: {
          favorited: is_favorited,
          favoritable_type: params[:favoritable_type],
          favoritable_id: params[:favoritable_id]
        }, status: :ok
      end

      private

      def find_favoritable
        favoritable_type = params[:favoritable_type]
        favoritable_id = params[:favoritable_id]

        return nil unless favoritable_type.present? && favoritable_id.present?

        case favoritable_type
        when 'Dish'
          Dish.find_by(id: favoritable_id)
        when 'SellerProfile', 'Seller'
          SellerProfile.find_by(id: favoritable_id)
        else
          nil
        end
      end

      def favorite_response(favorite)
        {
          id: favorite.id,
          favoritable_type: favorite.favoritable_type,
          favoritable_id: favorite.favoritable_id,
          favoritable: favoritable_summary(favorite.favoritable),
          created_at: favorite.created_at
        }
      end

      def favoritable_summary(favoritable)
        case favoritable
        when Dish
          {
            id: favoritable.id,
            name: favoritable.name,
            base_price: favoritable.base_price,
            seller_name: favoritable.seller_profile.business_name
          }
        when SellerProfile
          {
            id: favoritable.id,
            business_name: favoritable.business_name,
            city: favoritable.city,
            currently_active: favoritable.currently_active
          }
        else
          nil
        end
      end

      def dish_favorite_response(dish)
        {
          id: dish.id,
          name: dish.name,
          description: dish.description,
          base_price: dish.base_price,
          dietary_tags: dish.dietary_tags,
          active: dish.active,
          favorites_count: dish.favorites_count,
          is_favorited: true, # Since we're fetching favorited dishes
          seller: {
            id: dish.seller_profile.id,
            business_name: dish.seller_profile.business_name,
            city: dish.seller_profile.city,
            state: dish.seller_profile.state
          },
          photos: dish.photos.map { |photo|
            {
              url: photo.url,
              thumbnail_url: photo.variant(resize_to_limit: [200, 200]).processed.url
            } rescue nil
          }.compact,
          created_at: dish.created_at
        }
      end

      def seller_favorite_response(seller)
        {
          id: seller.id,
          business_name: seller.business_name,
          bio: seller.bio,
          phone: seller.phone,
          city: seller.city,
          state: seller.state,
          verified: seller.verified,
          currently_active: seller.currently_active,
          favorites_count: seller.favorites_count,
          is_favorited: true, # Since we're fetching favorited sellers
          current_location: seller.current_location ? {
            id: seller.current_location.id,
            name: seller.current_location.name,
            address: seller.current_location.address
          } : nil,
          arrived_at: seller.arrived_at,
          leaving_at: seller.leaving_at,
          created_at: seller.created_at
        }
      end
    end
  end
end
