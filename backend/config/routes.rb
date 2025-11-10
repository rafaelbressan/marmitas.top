Rails.application.routes.draw do
  # Devise routes (not used for API, kept for compatibility)
  devise_for :users, skip: :all

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post 'auth/register', to: 'auth#register'
      post 'auth/login', to: 'auth#login'
      delete 'auth/logout', to: 'auth#logout'
      get 'auth/me', to: 'auth#me'

      # Sellers (public browsing)
      resources :sellers, only: [:index, :show] do
        collection do
          get :nearby
        end
        member do
          get :menus, to: 'menus#seller_menus'
        end
      end

      # Menus (public browsing)
      resources :menus, only: [:index, :show] do
        collection do
          get :available_today
        end
      end

      # Seller management (authenticated sellers only)
      namespace :seller do
        resource :profile, only: [:show, :create, :update, :destroy]

        resources :dishes, only: [:index, :show, :create, :update, :destroy] do
          collection do
            get :favorites_stats
          end
        end

        resources :weekly_menus, only: [:index, :show, :create, :update, :destroy] do
          member do
            post :add_dish
            delete 'remove_dish/:dish_id', to: 'weekly_menus#remove_dish', as: :remove_dish
            post :duplicate
            get :whatsapp_text
          end
        end

        resources :selling_locations, only: [:index, :show, :create, :update, :destroy] do
          member do
            post :arrive
            post :leave
          end
        end
      end

      # Favorites
      resources :favorites, only: [:index, :create, :destroy] do
        collection do
          get :dishes
          get :sellers
          delete :remove
          get :check
        end
      end

      # Future routes
      # resources :reviews, only: [:index, :create, :update, :destroy]
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path for API info
  get "/" => proc { [200, {}, ['Marmitas.top API v1 - See /api/v1']] }
end
