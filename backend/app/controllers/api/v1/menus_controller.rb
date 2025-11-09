module Api
  module V1
    class MenusController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show, :available_today]

      # GET /api/v1/menus
      def index
        @menus = WeeklyMenu.active.available_now
                          .includes(seller_profile: :user, weekly_menu_dishes: { dish: :photos })
                          .order(created_at: :desc)

        # Filter by city
        if params[:city].present?
          @menus = @menus.joins(:seller_profile).where(seller_profiles: { city: params[:city] })
        end

        # Pagination
        @menus = @menus.page(params[:page]).per(params[:per_page] || 20)

        render json: {
          menus: @menus.map { |menu| menu_summary(menu) },
          pagination: pagination_meta(@menus)
        }, status: :ok
      end

      # GET /api/v1/menus/:id
      def show
        @menu = WeeklyMenu.find(params[:id])

        render json: {
          menu: menu_detail(@menu)
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Menu not found' }, status: :not_found
      end

      # GET /api/v1/menus/available_today
      def available_today
        @menus = WeeklyMenu.active.available_now
                          .includes(seller_profile: :user, weekly_menu_dishes: { dish: :photos })
                          .order(created_at: :desc)

        render json: {
          menus: @menus.map { |menu| menu_summary(menu) }
        }, status: :ok
      end

      # GET /api/v1/sellers/:seller_id/menus
      def seller_menus
        @seller = SellerProfile.find(params[:seller_id])
        @menus = @seller.weekly_menus.active.available_now
                        .includes(weekly_menu_dishes: { dish: :photos })
                        .order(available_from: :desc)

        render json: {
          menus: @menus.map { |menu| menu_summary(menu) }
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Seller not found' }, status: :not_found
      end

      private

      def menu_summary(menu)
        seller = menu.seller_profile
        {
          id: menu.id,
          title: menu.title,
          description: menu.description,
          available_from: menu.available_from,
          available_until: menu.available_until,
          dishes_count: menu.weekly_menu_dishes.count,
          total_available_quantity: menu.total_available_quantity,
          seller: {
            id: seller.id,
            business_name: seller.business_name,
            city: seller.city,
            state: seller.state,
            average_rating: seller.average_rating.to_f,
            verified: seller.verified
          },
          preview_dishes: menu.weekly_menu_dishes.ordered.limit(3).map { |md| dish_preview(md) }
        }
      end

      def menu_detail(menu)
        seller = menu.seller_profile
        {
          id: menu.id,
          title: menu.title,
          description: menu.description,
          available_from: menu.available_from,
          available_until: menu.available_until,
          is_available: menu.available?,
          seller: {
            id: seller.id,
            business_name: seller.business_name,
            bio: seller.bio,
            phone: seller.phone,
            whatsapp: seller.whatsapp,
            city: seller.city,
            state: seller.state,
            average_rating: seller.average_rating.to_f,
            reviews_count: seller.reviews_count,
            verified: seller.verified
          },
          dishes: menu.weekly_menu_dishes.ordered.map { |md| dish_detail(md) }
        }
      end

      def dish_preview(menu_dish)
        dish = menu_dish.dish
        {
          id: dish.id,
          name: dish.name,
          price: menu_dish.effective_price.to_f,
          remaining_quantity: menu_dish.remaining_quantity
        }
      end

      def dish_detail(menu_dish)
        dish = menu_dish.dish
        {
          id: menu_dish.id,
          dish_id: dish.id,
          name: dish.name,
          description: dish.description,
          price: menu_dish.effective_price.to_f,
          available_quantity: menu_dish.available_quantity,
          remaining_quantity: menu_dish.remaining_quantity,
          is_available: menu_dish.available?,
          dietary_tags: dish.dietary_tags,
          dietary_tags_display: dish.dietary_tags_display,
          photos: dish.photos.attached? ? dish.photos.map { |photo| rails_blob_url(photo) } : []
        }
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          per_page: collection.limit_value
        }
      end
    end
  end
end
