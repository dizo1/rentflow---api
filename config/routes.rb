Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Auth routes
      post 'login', to: 'auth#login'
      post 'signup', to: 'auth#signup'
      delete 'logout', to: 'auth#logout'
      post 'forgot_password', to: 'auth#forgot_password'
      post 'reset_password', to: 'auth#reset_password'

      # Profile routes
      get 'profile', to: 'users#profile'
      patch 'profile', to: 'users#update_profile'

      # Dashboard
      get 'dashboard', to: 'dashboard#show'

      # Analytics
      get 'analytics', to: 'analytics#index'

      # Users
      resources :users, only: [:index, :show, :update, :destroy]

      # Properties
      resources :properties, only: [:index, :show, :create, :update, :destroy] do
        post 'generate_rent', on: :member
        resources :units, only: [:index, :create] do
          resources :rent_records, only: [:index, :create]
          resources :maintenance_logs, only: [:index, :create]
        end
      end

      # Units
      resources :units, only: [:show, :update, :destroy] do
        resources :rent_records, only: [:index, :create]
        resources :maintenance_logs, only: [:index, :create]
        resource :tenant, only: [:show, :create]
        collection do
          get :vacant
        end
      end

      # Rent records
      resources :rent_records, only: [:show, :update, :destroy] do
        post 'record_payment', on: :member
      end

      # Maintenance logs
      resources :maintenance_logs, only: [:show, :update, :destroy] do
        patch :resolve, on: :member
      end

      # Tenants
      resources :tenants, only: [:index, :show, :update, :destroy]

      # Maintenance management
      get 'maintenance/dashboard', to: 'maintenance#dashboard'
      resources :maintenance, only: [:index, :show, :create, :update, :destroy] do
        patch 'resolve', on: :member
        collection do
          get 'properties/:property_id', to: 'maintenance#index', as: 'property'
        end
      end

      # Reminders
      resources :reminders, only: [:index, :show, :create, :update, :destroy]

      # Notifications
      resources :notifications, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch :read
          patch :unread
        end
        collection do
          patch :read_all
        end
      end

      # Payments
      resources :payments, only: [:index] do
        collection do
          post 'upgrade'
          post 'webhook'
        end
      end

      # Admin
      namespace :admin do
        get 'dashboard', to: 'admin#dashboard'
        get 'users', to: 'admin#users'
        get 'properties', to: 'admin#all_properties'
      end
    end
  end
end