class AutoExpireOrdersJob < ApplicationJob
  queue_as :default

  def perform
    expire_pickup_timeout_orders
    cancel_seller_broadcast_expired_orders
  end

  private

  # Expire confirmed orders where pickup_expires_at has passed (customer no-show)
  def expire_pickup_timeout_orders
    expired_orders = Order.confirmed
                          .where('pickup_expires_at < ?', Time.current)
                          .includes(:user, :seller_profile)

    expired_orders.each do |order|
      if order.expire!
        Rails.logger.info "⏰ Order ##{order.id} expired - pickup timeout"

        # Notify customer
        NotifyCustomerOrderUpdateJob.perform_later(order.id, 'expired')
      end
    end

    Rails.logger.info "Auto-expired #{expired_orders.count} orders (pickup timeout)" if expired_orders.any?
  end

  # Cancel pending orders where seller's broadcast has expired (seller never responded)
  def cancel_seller_broadcast_expired_orders
    # Find pending orders where seller is no longer active OR leaving_at has passed
    cancelled_count = 0

    Order.pending.includes(:seller_profile).find_each do |order|
      seller = order.seller_profile

      # Cancel if seller broadcast expired
      if seller.leaving_at && seller.leaving_at < Time.current
        if order.cancel!('Vendedor encerrou atividade sem confirmar pedido')
          Rails.logger.info "⏰ Order ##{order.id} cancelled - seller broadcast expired"

          # Notify customer
          NotifyCustomerOrderUpdateJob.perform_later(order.id, 'cancelled')

          cancelled_count += 1
        end
      end
    end

    Rails.logger.info "Auto-cancelled #{cancelled_count} pending orders (seller broadcast expired)" if cancelled_count > 0
  end
end
