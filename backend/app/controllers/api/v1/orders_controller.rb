module Api
  module V1
    class OrdersController < BaseController
      before_action :authenticate_user!
      before_action :set_order, only: [:show, :cancel, :complete]
      before_action :authorize_order, only: [:show, :cancel, :complete]

      # GET /api/v1/orders
      def index
        @orders = current_user.orders
                              .includes(:seller_profile, order_items: :dish)
                              .recent

        # Filter by status
        @orders = @orders.where(status: params[:status]) if params[:status].present?

        # Pagination
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        @orders = @orders.page(page).per(per_page)

        render json: {
          orders: @orders.map { |order| order_summary(order) },
          pagination: pagination_meta(@orders)
        }
      end

      # GET /api/v1/orders/:id
      def show
        render json: {
          order: order_detail(@order)
        }
      end

      # POST /api/v1/orders
      def create
        @order = current_user.orders.new(order_create_params)

        Order.transaction do
          # Build order items from params
          items_params = params[:items] || []

          items_params.each do |item_params|
            menu_dish = WeeklyMenuDish.find(item_params[:weekly_menu_dish_id])

            # Validate quantity available
            unless menu_dish.remaining_quantity >= item_params[:quantity].to_i
              return render json: {
                error: "Quantidade insuficiente para #{menu_dish.dish.name}. Apenas #{menu_dish.remaining_quantity} disponível(is)."
              }, status: :unprocessable_entity
            end

            @order.order_items.build(
              dish: menu_dish.dish,
              weekly_menu_dish: menu_dish,
              quantity: item_params[:quantity],
              unit_price: menu_dish.effective_price
            )
          end

          # Calculate total (items + delivery fee if applicable)
          items_total = @order.order_items.sum(&:subtotal)
          delivery_fee = 0

          if @order.seller_profile.offers_delivery && params[:order][:request_delivery]
            delivery_fee = @order.seller_profile.delivery_fee_amount || 0
          end

          @order.total_price = items_total + delivery_fee
          @order.delivery_fee = delivery_fee

          # Snapshot customer location if provided
          if params[:customer_latitude].present? && params[:customer_longitude].present?
            @order.customer_latitude = params[:customer_latitude]
            @order.customer_longitude = params[:customer_longitude]
          end

          if @order.save
            # Send notification to seller (async)
            NotifySellerNewOrderJob.perform_later(@order.id) if defined?(NotifySellerNewOrderJob)

            render json: {
              message: 'Pedido criado com sucesso',
              order: order_detail(@order)
            }, status: :created
          else
            render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
          end
        end
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'Item não encontrado' }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # DELETE /api/v1/orders/:id/cancel
      def cancel
        unless @order.can_cancel?
          return render json: {
            error: 'Este pedido não pode ser cancelado'
          }, status: :unprocessable_entity
        end

        cancellation_reason = params[:reason] || 'Cancelado pelo cliente'

        if @order.cancel!(cancellation_reason)
          # Notify seller
          NotifySellerOrderCancelledJob.perform_later(@order.id) if defined?(NotifySellerOrderCancelledJob)

          render json: {
            message: 'Pedido cancelado com sucesso',
            order: order_detail(@order)
          }
        else
          render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/orders/:id/complete
      def complete
        validation_code = params[:validation_code].to_s

        if validation_code.blank?
          return render json: { error: 'Código de validação é obrigatório' }, status: :unprocessable_entity
        end

        if @order.complete!(validation_code)
          render json: {
            message: 'Pedido concluído com sucesso! Obrigado!',
            order: order_detail(@order)
          }
        else
          render json: { error: 'Código de validação inválido ou pedido não está pronto para conclusão' }, status: :unprocessable_entity
        end
      end

      private

      def set_order
        @order = Order.find(params[:id])
      end

      def authorize_order
        unless @order.user_id == current_user.id
          render json: { error: 'Não autorizado' }, status: :forbidden
        end
      end

      def order_create_params
        params.require(:order).permit(:seller_profile_id, :weekly_menu_id, :request_delivery)
      end

      def order_summary(order)
        {
          id: order.id,
          status: order.status,
          total_price: order.total_price.to_f,
          delivery_fee: order.delivery_fee.to_f,
          order_date: order.order_date,
          pickup_expires_at: order.pickup_expires_at,
          items_count: order.order_items.count,
          seller: {
            id: order.seller_profile.id,
            business_name: order.seller_profile.business_name
          },
          can_cancel: order.can_cancel?,
          created_at: order.created_at
        }
      end

      def order_detail(order)
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
          seller: {
            id: order.seller_profile.id,
            business_name: order.seller_profile.business_name,
            phone: order.seller_profile.phone,
            whatsapp: order.seller_profile.whatsapp
          },
          seller_location: {
            name: order.seller_location_name,
            latitude: order.seller_latitude&.to_f,
            longitude: order.seller_longitude&.to_f
          },
          items: order.order_items.map { |item| order_item_response(item) },
          can_cancel: order.can_cancel?,
          awaiting_pickup: order.awaiting_pickup?,
          created_at: order.created_at,
          updated_at: order.updated_at
        }
      end

      def order_item_response(item)
        {
          id: item.id,
          dish_id: item.dish_id,
          dish_name: item.dish_name_snapshot,
          dish_description: item.dish_description_snapshot,
          quantity: item.quantity,
          unit_price: item.unit_price.to_f,
          subtotal: item.subtotal.to_f
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
