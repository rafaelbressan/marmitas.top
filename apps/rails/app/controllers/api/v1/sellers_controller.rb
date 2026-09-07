module Api
  module V1
    class SellersController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show, :nearby]

      # GET /api/v1/sellers
      def index
        @sellers = SellerProfile.verified.includes(:user)
        @sellers = apply_filters(@sellers)

        # Prioritize favorited sellers if user is authenticated
        if current_user.present?
          favorited_ids = current_user.favorited_sellers.pluck(:id)
          @sellers = @sellers.order(
            Arel.sql("CASE WHEN seller_profiles.id IN (#{favorited_ids.any? ? favorited_ids.join(',') : '0'}) THEN 0 ELSE 1 END"),
            created_at: :desc
          )
        end

        @sellers = @sellers.page(params[:page]).per(params[:per_page] || 20)

        render json: {
          sellers: @sellers.map { |seller| seller_summary(seller) },
          pagination: pagination_meta(@sellers)
        }, status: :ok
      end

      # GET /api/v1/sellers/:id
      def show
        @seller = SellerProfile.find(params[:id])
        render json: { seller: seller_detail(@seller) }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Seller not found' }, status: :not_found
      end

      # GET /api/v1/sellers/nearby
      def nearby
        unless params[:latitude] && params[:longitude]
          return render json: { error: 'Latitude and longitude required' }, status: :bad_request
        end

        lat = params[:latitude].to_f
        lng = params[:longitude].to_f
        radius = params[:radius]&.to_f || 5.0

        # Use PostGIS-based nearby search
        @sellers = SellerProfile.verified
                                 .nearby(lat, lng, radius)
                                 .includes(:user, :current_location)
                                 .limit(50)

        # Apply favorited sellers priority
        if current_user.present?
          favorited_ids = current_user.favorited_sellers.pluck(:id)

          # Re-sort to prioritize favorited sellers, then by distance
          sellers_array = @sellers.to_a
          favorited_sellers = sellers_array.select { |s| favorited_ids.include?(s.id) }
          non_favorited_sellers = sellers_array.reject { |s| favorited_ids.include?(s.id) }

          @sellers = favorited_sellers + non_favorited_sellers
        end

        render json: {
          sellers: @sellers.map { |seller| seller_summary(seller, include_distance: true) },
          search_params: {
            latitude: lat,
            longitude: lng,
            radius_km: radius
          }
        }, status: :ok
      end

      private

      def apply_filters(scope)
        scope = scope.where(city: params[:city]) if params[:city].present?
        scope = scope.where('average_rating >= ?', params[:min_rating]) if params[:min_rating].present?
        scope = scope.where(currently_active: true) if params[:active_only] == 'true'
        scope
      end

      def seller_summary(seller, include_distance: false)
        summary = {
          id: seller.id,
          business_name: seller.business_name,
          bio: seller.bio&.truncate(150),
          city: seller.city,
          state: seller.state,
          average_rating: seller.average_rating.to_f,
          reviews_count: seller.reviews_count,
          followers_count: seller.followers_count,
          favorites_count: seller.favorites_count,
          verified: seller.verified,
          currently_active: seller.currently_active,
          has_current_menu: seller.current_menu.present?
        }

        # Include distance if available (from nearby search)
        if include_distance && seller.respond_to?(:distance_km)
          summary[:distance_km] = seller.distance_km.to_f.round(2)
        end

        # Include current location for map display
        if seller.current_location.present?
          summary[:current_location] = {
            id: seller.current_location.id,
            name: seller.current_location.name,
            address: seller.current_location.address,
            latitude: seller.current_location.latitude,
            longitude: seller.current_location.longitude
          }
        end

        summary[:is_favorited] = current_user.favorited?(seller) if current_user.present?
        summary
      end

      def seller_detail(seller)
        detail = {
          id: seller.id,
          business_name: seller.business_name,
          bio: seller.bio,
          phone: seller.phone,
          whatsapp: seller.whatsapp,
          city: seller.city,
          state: seller.state,
          operating_hours: seller.operating_hours,
          average_rating: seller.average_rating.to_f,
          reviews_count: seller.reviews_count,
          followers_count: seller.followers_count,
          favorites_count: seller.favorites_count,
          verified: seller.verified,
          currently_active: seller.currently_active,
          last_active_at: seller.last_active_at,
          arrived_at: seller.arrived_at,
          leaving_at: seller.leaving_at,
          current_menu: seller.current_menu ? menu_summary(seller.current_menu) : nil,
          current_location: seller.current_location ? location_summary(seller.current_location) : nil,
          selling_locations: seller.selling_locations.map { |loc| location_summary(loc) }
        }
        detail[:is_favorited] = current_user.favorited?(seller) if current_user.present?
        detail
      end

      def menu_summary(menu)
        {
          id: menu.id,
          title: menu.title,
          description: menu.description,
          available_from: menu.available_from,
          available_until: menu.available_until,
          dishes_count: menu.weekly_menu_dishes.count,
          total_available_quantity: menu.total_available_quantity
        }
      end

      def location_summary(location)
        {
          id: location.id,
          name: location.name,
          address: location.address,
          latitude: location.latitude.to_f,
          longitude: location.longitude.to_f
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
