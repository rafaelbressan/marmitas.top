class NotifySellerNewOrderJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order

    seller = order.seller_profile.user

    # Log notification
    Rails.logger.info "🔔 New order notification for seller #{seller.id}: Order ##{order.id}"

    # Send push notification to seller's active devices
    seller.device_tokens.where(active: true).each do |device_token|
      send_push_notification(
        device_token,
        "Novo Pedido ##{order.id}!",
        "#{order.user.name} fez um pedido de R$ #{order.total_price.to_f.round(2)}",
        {
          type: 'new_order',
          order_id: order.id,
          screen: 'SellerOrderDetail'
        }
      )
    end
  rescue => e
    Rails.logger.error "Failed to send new order notification: #{e.message}"
  end

  private

  def send_push_notification(device_token, title, body, data)
    # TODO: Implement FCM push notification
    # For now, just log
    Rails.logger.info "Push to #{device_token.platform}: #{title} - #{body}"
  end
end
