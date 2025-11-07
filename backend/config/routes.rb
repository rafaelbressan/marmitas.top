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
      end

      # Seller management (authenticated sellers only)
      namespace :seller do
        resource :profile, only: [:show, :create, :update, :destroy]
        # resources :menus, only: [:index, :create, :update, :destroy]
        # resources :locations, only: [:index, :create, :update, :destroy]
      end

      # Future routes
      # resources :favorites, only: [:index, :create, :destroy]
      # resources :reviews, only: [:index, :create, :update, :destroy]
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path for API info
  get "/" => proc { [200, {}, ['Marmitas.top API v1 - See /api/v1']] }
end
