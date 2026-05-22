class NotifyCustomerOrderCancelledJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order

    customer = order.user

    # Log notification
    Rails.logger.info "🔔 Order cancelled notification for customer #{customer.id}: Order ##{order.id}"

    # Send push notification to customer's active devices
    customer.device_tokens.where(active: true).each do |device_token|
      send_push_notification(
        device_token,
        "Pedido ##{order.id} Cancelado",
        order.cancellation_reason || "Pedido cancelado pelo vendedor",
        {
          type: 'order_cancelled',
          order_id: order.id,
          screen: 'OrderDetail'
        }
      )
    end
  rescue => e
    Rails.logger.error "Failed to send order cancelled notification to customer: #{e.message}"
  end

  private

  def send_push_notification(device_token, title, body, data)
    # TODO: Implement FCM push notification
    # For now, just log
    Rails.logger.info "Push to #{device_token.platform}: #{title} - #{body}"
  end
end
