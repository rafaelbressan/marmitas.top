module Api
  module V1
    class DeviceTokensController < ApplicationController
      before_action :authenticate_user!
      before_action :set_device_token, only: [:destroy]

      # GET /api/v1/device_tokens
      def index
        @tokens = current_user.device_tokens.order(last_used_at: :desc, created_at: :desc)

        render json: {
          device_tokens: @tokens.map { |token| device_token_response(token) }
        }, status: :ok
      end

      # POST /api/v1/device_tokens
      def create
        # Find existing token or create new one
        @token = current_user.device_tokens.find_or_initialize_by(
          token: device_token_params[:token],
          platform: device_token_params[:platform]
        )

        # Update attributes
        @token.assign_attributes(
          device_name: device_token_params[:device_name],
          active: true,
          last_used_at: Time.current
        )

        if @token.save
          render json: {
            message: 'Device token registered successfully',
            device_token: device_token_response(@token)
          }, status: @token.previously_new_record? ? :created : :ok
        else
          render json: { errors: @token.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/device_tokens/:id
      def destroy
        @token.destroy

        render json: { message: 'Device token removed successfully' }, status: :ok
      end

      # POST /api/v1/device_tokens/deactivate_all
      def deactivate_all
        current_user.device_tokens.active.each(&:deactivate!)

        render json: { message: 'All device tokens deactivated successfully' }, status: :ok
      end

      private

      def set_device_token
        @token = current_user.device_tokens.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Device token not found' }, status: :not_found
      end

      def device_token_params
        params.require(:device_token).permit(:token, :platform, :device_name)
      end

      def device_token_response(token)
        {
          id: token.id,
          platform: token.platform,
          device_name: token.device_name,
          active: token.active,
          last_used_at: token.last_used_at,
          created_at: token.created_at
        }
      end
    end
  end
end
