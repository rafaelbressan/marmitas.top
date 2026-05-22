class NotifyCustomerOrderUpdateJob < ApplicationJob
  queue_as :default

  def perform(order_id, new_status)
    order = Order.find_by(id: order_id)
    return unless order

    customer = order.user
    message = status_message(new_status, order)

    # Log notification
    Rails.logger.info "🔔 Order update notification for customer #{customer.id}: Order ##{order.id} -> #{new_status}"

    # Send push notification to customer's active devices
    customer.device_tokens.where(active: true).each do |device_token|
      send_push_notification(
        device_token,
        "Pedido ##{order.id} Atualizado",
        message,
        {
          type: 'order_update',
          order_id: order.id,
          status: new_status,
          screen: 'OrderDetail'
        }
      )
    end
  rescue => e
    Rails.logger.error "Failed to send order update notification: #{e.message}"
  end

  private

  def status_message(status, order)
    case status
    when 'confirmed'
      "Seu pedido foi confirmado! Pickup até #{order.pickup_expires_at&.strftime('%H:%M')}"
    when 'completed'
      'Pedido concluído. Obrigado!'
    when 'cancelled'
      "Pedido cancelado. #{order.cancellation_reason}"
    when 'expired'
      'Pedido expirou - tempo de retirada passou'
    else
      'Atualização do pedido'
    end
  end

  def send_push_notification(device_token, title, body, data)
    # TODO: Implement FCM push notification
    # For now, just log
    Rails.logger.info "Push to #{device_token.platform}: #{title} - #{body}"
  end
end
