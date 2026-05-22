class NotifySellerOrderCancelledJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order

    seller = order.seller_profile.user

    # Log notification
    Rails.logger.info "🔔 Order cancelled notification for seller #{seller.id}: Order ##{order.id}"

    # Send push notification to seller's active devices
    seller.device_tokens.where(active: true).each do |device_token|
      send_push_notification(
        device_token,
        "Pedido ##{order.id} Cancelado",
        "Cliente cancelou pedido de R$ #{order.total_price.to_f.round(2)}",
        {
          type: 'order_cancelled',
          order_id: order.id,
          screen: 'SellerOrderDetail'
        }
      )
    end
  rescue => e
    Rails.logger.error "Failed to send order cancelled notification to seller: #{e.message}"
  end

  private

  def send_push_notification(device_token, title, body, data)
    # TODO: Implement FCM push notification
    # For now, just log
    Rails.logger.info "Push to #{device_token.platform}: #{title} - #{body}"
  end
end
