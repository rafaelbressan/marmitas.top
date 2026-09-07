module Api
  module V1
    module Seller
      class WeeklyMenusController < BaseController
        before_action :set_menu, only: [:show, :update, :destroy, :add_dish, :remove_dish, :duplicate, :whatsapp_text]

        # GET /api/v1/seller/weekly_menus
        def index
          @menus = current_user.seller_profile.weekly_menus.order(available_from: :desc)

          # Filter by status
          @menus = case params[:status]
                   when 'active'
                     @menus.available_now
                   when 'upcoming'
                     @menus.upcoming
                   when 'past'
                     @menus.past
                   else
                     @menus
                   end

          render json: {
            menus: @menus.map { |menu| menu_summary(menu) }
          }, status: :ok
        end

        # GET /api/v1/seller/weekly_menus/:id
        def show
          render json: { menu: menu_detail(@menu) }, status: :ok
        end

        # POST /api/v1/seller/weekly_menus
        def create
          unless current_user.seller_profile
            return render json: { error: 'Seller profile required' }, status: :forbidden
          end

          @menu = current_user.seller_profile.weekly_menus.build(menu_params)

          if @menu.save
            render json: {
              message: 'Daily menu created successfully',
              menu: menu_detail(@menu)
            }, status: :created
          else
            render json: { errors: @menu.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/seller/weekly_menus/:id
        def update
          if @menu.update(menu_params)
            render json: {
              message: 'Daily menu updated successfully',
              menu: menu_detail(@menu)
            }, status: :ok
          else
            render json: { errors: @menu.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/seller/weekly_menus/:id
        def destroy
          if @menu.available?
            return render json: {
              error: 'Cannot delete an active menu'
            }, status: :unprocessable_entity
          end

          @menu.destroy
          render json: { message: 'Daily menu deleted successfully' }, status: :ok
        end

        # POST /api/v1/seller/weekly_menus/:id/add_dish
        def add_dish
          dish = current_user.seller_profile.dishes.find(params[:dish_id])

          menu_dish = @menu.weekly_menu_dishes.build(
            dish: dish,
            available_quantity: params[:available_quantity],
            price_override: params[:price_override],
            display_order: params[:display_order] || @menu.weekly_menu_dishes.count
          )

          if menu_dish.save
            render json: {
              message: 'Dish added to menu successfully',
              menu: menu_detail(@menu.reload)
            }, status: :ok
          else
            render json: { errors: menu_dish.errors.full_messages }, status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Dish not found' }, status: :not_found
        end

        # DELETE /api/v1/seller/weekly_menus/:id/remove_dish/:dish_id
        def remove_dish
          menu_dish = @menu.weekly_menu_dishes.find_by(dish_id: params[:dish_id])

          unless menu_dish
            return render json: { error: 'Dish not in menu' }, status: :not_found
          end

          menu_dish.destroy
          render json: {
            message: 'Dish removed from menu successfully',
            menu: menu_detail(@menu.reload)
          }, status: :ok
        end

        # POST /api/v1/seller/weekly_menus/:id/duplicate
        def duplicate
          new_available_from = params[:available_from]&.to_datetime
          new_available_until = params[:available_until]&.to_datetime

          begin
            new_menu = @menu.duplicate(
              new_available_from: new_available_from,
              new_available_until: new_available_until
            )

            render json: {
              message: 'Menu duplicated successfully',
              menu: menu_detail(new_menu)
            }, status: :created
          rescue => e
            render json: { error: e.message }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/seller/weekly_menus/:id/whatsapp_text
        def whatsapp_text
          render json: {
            message: @menu.whatsapp_message,
            encoded_message: ERB::Util.url_encode(@menu.whatsapp_message)
          }, status: :ok
        end

        private

        def set_menu
          @menu = current_user.seller_profile.weekly_menus.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Menu not found' }, status: :not_found
        end

        def menu_params
          params.require(:weekly_menu).permit(
            :title,
            :description,
            :available_from,
            :available_until,
            :active
          )
        end

        def menu_summary(menu)
          {
            id: menu.id,
            title: menu.title,
            description: menu.description,
            available_from: menu.available_from,
            available_until: menu.available_until,
            active: menu.active,
            is_available: menu.available?,
            dishes_count: menu.weekly_menu_dishes.count,
            total_available_quantity: menu.total_available_quantity,
            total_orders_count: menu.total_orders_count,
            created_at: menu.created_at
          }
        end

        def menu_detail(menu)
          {
            id: menu.id,
            title: menu.title,
            description: menu.description,
            available_from: menu.available_from,
            available_until: menu.available_until,
            active: menu.active,
            is_available: menu.available?,
            total_orders_count: menu.total_orders_count,
            dishes: menu.weekly_menu_dishes.ordered.map { |menu_dish| menu_dish_response(menu_dish) },
            created_at: menu.created_at,
            updated_at: menu.updated_at
          }
        end

        def menu_dish_response(menu_dish)
          dish = menu_dish.dish
          {
            id: menu_dish.id,
            dish_id: dish.id,
            dish_name: dish.name,
            description: dish.description,
            base_price: dish.base_price.to_f,
            price_override: menu_dish.price_override&.to_f,
            effective_price: menu_dish.effective_price.to_f,
            available_quantity: menu_dish.available_quantity,
            remaining_quantity: menu_dish.remaining_quantity,
            is_available: menu_dish.available?,
            dietary_tags: dish.dietary_tags,
            display_order: menu_dish.display_order,
            photos: dish.photos.attached? ? dish.photos.map { |photo| rails_blob_url(photo) } : []
          }
        end
      end
    end
  end
end
