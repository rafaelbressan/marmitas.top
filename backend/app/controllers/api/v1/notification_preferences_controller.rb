module Api
  module V1
    class NotificationPreferencesController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/notification_preferences
      def show
        render json: {
          notification_preferences: current_user.notification_preferences
        }, status: :ok
      end

      # PATCH /api/v1/notification_preferences
      def update
        preferences = current_user.notification_preferences.merge(preferences_params)

        if current_user.update(notification_preferences: preferences)
          render json: {
            message: 'Notification preferences updated successfully',
            notification_preferences: current_user.notification_preferences
          }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def preferences_params
        params.require(:notification_preferences).permit(
          :seller_arrivals,
          :new_menus,
          :order_updates,
          :promotions
        ).to_h.transform_values { |v| ActiveModel::Type::Boolean.new.cast(v) }
      end
    end
  end
end
