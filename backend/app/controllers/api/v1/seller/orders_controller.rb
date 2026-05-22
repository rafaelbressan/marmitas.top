module Api
  module V1
    module Seller
      class OrdersController < BaseController
        before_action :authenticate_user!
        before_action :require_seller_profile
        before_action :set_order, only: [:show, :update_status]

        # GET /api/v1/seller/orders
        def index
          @orders = current_user.seller_profile.orders
                                .includes(:user, order_items: :dish)
                                .recent

          # Filter by status/type
          case params[:filter]
          when 'pending'
            @orders = @orders.pending
          when 'active'
            @orders = @orders.active
          when 'confirmed'
            @orders = @orders.confirmed
          when 'completed'
            @orders = @orders.completed
          when 'today'
            @orders = @orders.today
          end

          # Pagination
          page = params[:page] || 1
          per_page = params[:per_page] || 20
          @orders = @orders.page(page).per(per_page)

          render json: {
            orders: @orders.map { |order| seller_order_summary(order) },
            pagination: pagination_meta(@orders),
            stats: order_stats
          }
        end

        # GET /api/v1/seller/orders/:id
        def show
          render json: {
            order: seller_order_detail(@order)
          }
        end

        # PATCH /api/v1/seller/orders/:id/update_status
        def update_status
          new_status = params[:status]

          success = case new_status
                    when 'confirmed'
                      @order.confirm!
                    when 'completed'
                      # Seller can mark as completed without validation code
                      # (for in-person sales where customer doesn't have app)
                      if @order.confirmed?
                        @order.update(status: 'completed', completed_at: Time.current)
                      else
                        false
                      end
                    else
                      false
                    end

          if success
            # Send notification to customer (async)
            NotifyCustomerOrderUpdateJob.perform_later(@order.id, new_status) if defined?(NotifyCustomerOrderUpdateJob)

            render json: {
              message: 'Status atualizado com sucesso',
              order: seller_order_detail(@order)
            }
          else
            render json: {
              error: 'Não foi possível atualizar o status'
            }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/seller/orders/:id/cancel
        def cancel
          unless @order.can_cancel?
            return render json: {
              error: 'Este pedido não pode ser cancelado'
            }, status: :unprocessable_entity
          end

          cancellation_reason = params[:reason] || 'Cancelado pelo vendedor'

          if @order.cancel!(cancellation_reason)
            # Notify customer
            NotifyCustomerOrderCancelledJob.perform_later(@order.id) if defined?(NotifyCustomerOrderCancelledJob)

            render json: {
              message: 'Pedido cancelado com sucesso',
              order: seller_order_detail(@order)
            }
          else
            render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def require_seller_profile
          unless current_user.seller_profile
            render json: { error: 'Perfil de vendedor necessário' }, status: :forbidden
          end
        end

        def set_order
          @order = current_user.seller_profile.orders.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Pedido não encontrado' }, status: :not_found
        end

        def seller_order_summary(order)
          {
            id: order.id,
            status: order.status,
            total_price: order.total_price.to_f,
            delivery_fee: order.delivery_fee.to_f,
            order_date: order.order_date,
            pickup_expires_at: order.pickup_expires_at,
            items_count: order.order_items.count,
            customer: {
              id: order.user.id,
              name: order.user.name,
              phone: order.user.phone
            },
            completion_code: order.completion_code,
            created_at: order.created_at
          }
        end

        def seller_order_detail(order)
          {
            id: order.id,
            status: order.status,
            total_price: order.total_price.to_f,
            delivery_fee: order.delivery_fee.to_f,
            order_date: order.order_date,
            pickup_expires_at: order.pickup_expires_at,
            confirmed_at: order.confirmed_at,
            completed_at: order.completed_at,
            cancelled_at: order.cancelled_at,
            expired_at: order.expired_at,
            cancellation_reason: order.cancellation_reason,
            completion_code: order.completion_code,
            customer: {
              id: order.user.id,
              name: order.user.name,
              phone: order.user.phone
            },
            customer_location: {
              latitude: order.customer_latitude&.to_f,
              longitude: order.customer_longitude&.to_f
            },
            items: order.order_items.map { |item| seller_order_item_response(item) },
            can_cancel: order.can_cancel?,
            created_at: order.created_at,
            updated_at: order.updated_at
          }
        end

        def seller_order_item_response(item)
          {
            id: item.id,
            dish_name: item.dish_name_snapshot,
            dish_description: item.dish_description_snapshot,
            quantity: item.quantity,
            unit_price: item.unit_price.to_f,
            subtotal: item.subtotal.to_f
          }
        end

        def order_stats
          seller = current_user.seller_profile

          {
            pending_count: seller.orders.pending.count,
            confirmed_count: seller.orders.confirmed.count,
            today_count: seller.orders.today.count,
            total_count: seller.total_orders_count,
            completed_count: seller.completed_orders_count
          }
        end

        def pagination_meta(collection)
          {
            current_page: collection.current_page,
            total_pages: collection.total_pages,
            total_count: collection.total_count,
            per_page: collection.limit_value
          }
        end
      end
    end
  end
end
