class NotifyFollowersJob < ApplicationJob
  queue_as :default

  # Retry up to 3 times with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(seller_profile_id, notification_type)
    seller_profile = SellerProfile.find_by(id: seller_profile_id)
    return unless seller_profile

    case notification_type
    when 'arrival'
      PushNotificationService.notify_seller_arrival(seller_profile)
    when 'departure'
      # Could notify about departure too if needed
      Rails.logger.info "Seller #{seller_profile.business_name} departed"
    else
      Rails.logger.warn "Unknown notification type: #{notification_type}"
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "SellerProfile not found: #{e.message}"
  end
end
