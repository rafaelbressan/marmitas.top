module Api
  module V1
    module Seller
      class ProfilesController < BaseController
        before_action :set_profile, only: [:show, :update]

        # GET /api/v1/seller/profile
        def show
          if @profile
            render json: profile_response(@profile), status: :ok
          else
            render json: { error: 'Seller profile not found. Create one first.' }, status: :not_found
          end
        end

        # POST /api/v1/seller/profile
        def create
          if current_user.seller_profile
            return render json: { error: 'Seller profile already exists' }, status: :unprocessable_entity
          end

          @profile = current_user.build_seller_profile(profile_params)

          if @profile.save
            render json: {
              message: 'Seller profile created successfully',
              profile: profile_response(@profile)
            }, status: :created
          else
            render json: { errors: @profile.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/seller/profile
        def update
          unless @profile
            return render json: { error: 'Seller profile not found' }, status: :not_found
          end

          if @profile.update(profile_params)
            render json: {
              message: 'Seller profile updated successfully',
              profile: profile_response(@profile)
            }, status: :ok
          else
            render json: { errors: @profile.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/seller/profile
        def destroy
          unless @profile
            return render json: { error: 'Seller profile not found' }, status: :not_found
          end

          @profile.destroy
          render json: { message: 'Seller profile deleted successfully' }, status: :ok
        end

        private

        def set_profile
          @profile = current_user.seller_profile
        end

        def profile_params
          params.require(:seller_profile).permit(
            :business_name, :bio, :phone, :whatsapp,
            :city, :state, :operating_hours
          )
        end

        def profile_response(profile)
          {
            id: profile.id,
            user_id: profile.user_id,
            business_name: profile.business_name,
            bio: profile.bio,
            phone: profile.phone,
            whatsapp: profile.whatsapp,
            city: profile.city,
            state: profile.state,
            operating_hours: profile.operating_hours,
            followers_count: profile.followers_count,
            average_rating: profile.average_rating.to_f,
            reviews_count: profile.reviews_count,
            verified: profile.verified,
            currently_active: profile.currently_active,
            last_active_at: profile.last_active_at,
            created_at: profile.created_at,
            updated_at: profile.updated_at
          }
        end
      end
    end
  end
end
