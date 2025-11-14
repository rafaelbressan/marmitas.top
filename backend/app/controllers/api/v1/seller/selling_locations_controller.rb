module Api
  module V1
    module Seller
      class SellingLocationsController < BaseController
        before_action :set_location, only: [:show, :update, :destroy, :arrive, :leave]

        # GET /api/v1/seller/selling_locations
        def index
          @locations = current_user.seller_profile.selling_locations.order(created_at: :asc)

          render json: {
            locations: @locations.map { |location| location_response(location) }
          }, status: :ok
        end

        # GET /api/v1/seller/selling_locations/:id
        def show
          render json: { location: location_response(@location) }, status: :ok
        end

        # POST /api/v1/seller/selling_locations
        def create
          unless current_user.seller_profile
            return render json: { error: 'Seller profile required' }, status: :forbidden
          end

          @location = current_user.seller_profile.selling_locations.build(location_params)

          if @location.save
            render json: {
              message: 'Selling location created successfully',
              location: location_response(@location)
            }, status: :created
          else
            render json: { errors: @location.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/seller/selling_locations/:id
        def update
          if @location.update(location_params)
            render json: {
              message: 'Selling location updated successfully',
              location: location_response(@location)
            }, status: :ok
          else
            render json: { errors: @location.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/seller/selling_locations/:id
        def destroy
          # Don't allow deleting current active location
          if current_user.seller_profile.current_location_id == @location.id
            return render json: {
              error: 'Cannot delete location while broadcasting from it. Please leave first.'
            }, status: :unprocessable_entity
          end

          @location.destroy
          render json: { message: 'Selling location deleted successfully' }, status: :ok
        end

        # POST /api/v1/seller/selling_locations/:id/arrive
        def arrive
          # Check if already broadcasting from another location
          if current_user.seller_profile.currently_active && current_user.seller_profile.current_location_id != @location.id
            current_location = current_user.seller_profile.current_location
            return render json: {
              error: "Already broadcasting from #{current_location.name}. Please leave first."
            }, status: :unprocessable_entity
          end

          leaving_at = parse_leaving_time

          begin
            current_user.seller_profile.announce_arrival(@location.id, leaving_at: leaving_at)

            render json: {
              message: 'Arrival announced successfully',
              seller: seller_broadcast_status
            }, status: :ok
          rescue ActiveRecord::RecordInvalid => e
            render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # POST /api/v1/seller/selling_locations/:id/leave
        def leave
          unless current_user.seller_profile.currently_active
            return render json: { error: 'Not currently broadcasting' }, status: :unprocessable_entity
          end

          unless current_user.seller_profile.current_location_id == @location.id
            return render json: { error: 'Not at this location' }, status: :unprocessable_entity
          end

          current_user.seller_profile.announce_departure

          render json: {
            message: 'Departure announced successfully',
            seller: seller_broadcast_status
          }, status: :ok
        end

        private

        def set_location
          @location = current_user.seller_profile.selling_locations.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Location not found' }, status: :not_found
        end

        def location_params
          params.require(:selling_location).permit(
            :name,
            :address,
            :latitude,
            :longitude,
            :notes
          )
        end

        def parse_leaving_time
          return nil unless params[:leaving_at].present? || params[:hours_from_now].present?

          if params[:leaving_at].present?
            Time.parse(params[:leaving_at])
          elsif params[:hours_from_now].present?
            hours = params[:hours_from_now].to_f
            max_hours = (SellerProfile::MAX_BROADCAST_DURATION / 1.hour).to_i
            if hours > max_hours
              raise ActiveRecord::RecordInvalid.new(current_user.seller_profile.tap { |sp|
                sp.errors.add(:leaving_at, "cannot be more than #{max_hours} hours from now")
              })
            end
            Time.current + hours.hours
          end
        end

        def location_response(location)
          {
            id: location.id,
            name: location.name,
            address: location.address,
            latitude: location.latitude&.to_f,
            longitude: location.longitude&.to_f,
            notes: location.notes,
            is_current: current_user.seller_profile.current_location_id == location.id,
            created_at: location.created_at,
            updated_at: location.updated_at
          }
        end

        def seller_broadcast_status
          profile = current_user.seller_profile.reload
          {
            id: profile.id,
            business_name: profile.business_name,
            currently_active: profile.currently_active,
            current_location: profile.current_location ? {
              id: profile.current_location.id,
              name: profile.current_location.name,
              address: profile.current_location.address
            } : nil,
            arrived_at: profile.arrived_at,
            leaving_at: profile.leaving_at,
            broadcast_expired: profile.broadcast_expired?
          }
        end
      end
    end
  end
end
