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

      # Future routes will go here
      # resources :marmiteiros, only: [:index, :show]
      # resources :favorites, only: [:index, :create, :destroy]
      # resources :reviews, only: [:index, :create, :update, :destroy]
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path for API info
  get "/" => proc { [200, {}, ['Marmitas.top API v1 - See /api/v1']] }
end
