module Api
  module V1
    class MapController < BaseController
      skip_before_action :authenticate_user!, only: [:sellers]

      # GET /api/v1/map/sellers
      # Returns active sellers with their locations in a map-friendly format
      def sellers
        unless params[:latitude] && params[:longitude]
          return render json: { error: 'Latitude and longitude required' }, status: :bad_request
        end

        lat = params[:latitude].to_f
        lng = params[:longitude].to_f
        radius = params[:radius]&.to_f || 10.0 # Default 10km for map view

        # Get nearby active sellers with their current locations
        @sellers = SellerProfile.verified
                                 .nearby(lat, lng, radius)
                                 .includes(:user, :current_location)
                                 .limit(100)

        # Convert to GeoJSON-compatible format
        features = @sellers.map do |seller|
          {
            type: 'Feature',
            geometry: {
              type: 'Point',
              coordinates: [
                seller.current_location.longitude.to_f,
                seller.current_location.latitude.to_f
              ]
            },
            properties: {
              id: seller.id,
              business_name: seller.business_name,
              bio: seller.bio&.truncate(100),
              city: seller.city,
              state: seller.state,
              verified: seller.verified,
              distance_km: seller.respond_to?(:distance_km) ? seller.distance_km.to_f.round(2) : nil,
              favorites_count: seller.favorites_count,
              is_favorited: current_user.present? ? current_user.favorited?(seller) : false,
              has_current_menu: seller.current_menu.present?,
              location: {
                id: seller.current_location.id,
                name: seller.current_location.name,
                address: seller.current_location.address
              },
              arrived_at: seller.arrived_at,
              leaving_at: seller.leaving_at
            }
          }
        end

        render json: {
          type: 'FeatureCollection',
          features: features,
          metadata: {
            total_sellers: features.count,
            search_center: {
              latitude: lat,
              longitude: lng
            },
            radius_km: radius
          }
        }, status: :ok
      end

      # GET /api/v1/map/bounds
      # Returns sellers within a bounding box (for map pan/zoom)
      def bounds
        unless params[:ne_lat] && params[:ne_lng] && params[:sw_lat] && params[:sw_lng]
          return render json: {
            error: 'Bounding box required (ne_lat, ne_lng, sw_lat, sw_lng)'
          }, status: :bad_request
        end

        ne_lat = params[:ne_lat].to_f
        ne_lng = params[:ne_lng].to_f
        sw_lat = params[:sw_lat].to_f
        sw_lng = params[:sw_lng].to_f

        # Find sellers within the bounding box
        @sellers = SellerProfile.verified
                                 .joins(:current_location)
                                 .where(currently_active: true)
                                 .where(
                                   'selling_locations.latitude BETWEEN ? AND ? AND
                                    selling_locations.longitude BETWEEN ? AND ?',
                                   sw_lat, ne_lat, sw_lng, ne_lng
                                 )
                                 .includes(:user, :current_location)
                                 .limit(200)

        features = @sellers.map do |seller|
          {
            type: 'Feature',
            geometry: {
              type: 'Point',
              coordinates: [
                seller.current_location.longitude.to_f,
                seller.current_location.latitude.to_f
              ]
            },
            properties: {
              id: seller.id,
              business_name: seller.business_name,
              verified: seller.verified,
              favorites_count: seller.favorites_count,
              is_favorited: current_user.present? ? current_user.favorited?(seller) : false,
              has_current_menu: seller.current_menu.present?,
              location: {
                name: seller.current_location.name,
                address: seller.current_location.address
              }
            }
          }
        end

        render json: {
          type: 'FeatureCollection',
          features: features,
          metadata: {
            total_sellers: features.count,
            bounds: {
              ne: { lat: ne_lat, lng: ne_lng },
              sw: { lat: sw_lat, lng: sw_lng }
            }
          }
        }, status: :ok
      end
    end
  end
end
