Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      get 'dashboard', to: 'dashboard#show'
      post 'login', to: 'auth#login'
      post 'signup', to: 'auth#signup'
      get 'profile', to: 'users#profile'
      resources :users, only: [:index, :show, :update, :destroy]
      resources :properties, only: [:index, :show, :create, :update, :destroy] do
        post 'generate_rent', on: :member
        resources :units, only: [:index, :create] do
          resources :rent_records, only: [:index, :create]
          resources :maintenance_logs, only: [:index, :create]
        end
      end
      resources :units, only: [:show, :update, :destroy] do
        resources :rent_records, only: [:index, :create]
        resources :maintenance_logs, only: [:index, :create]
      end
       resources :rent_records, only: [:show, :update, :destroy] do
         post 'record_payment', on: :member
       end
       resources :maintenance_logs, only: [:show, :update, :destroy] do
         patch :resolve, on: :member
       end

       delete 'logout', to: 'auth#logout'

       # Tenant management routes
       resources :tenants, only: [:index, :show, :update, :destroy]
       resources :units, only: [] do
         resource :tenant, only: [:show, :create]
       end

       # Maintenance management routes
       get 'maintenance/dashboard', to: 'maintenance#dashboard'
       resources :maintenance, only: [:index, :show, :create, :update, :destroy] do
         patch 'resolve', on: :member
         collection do
           get 'properties/:property_id', to: 'maintenance#index', as: 'property'
         end
       end

       post 'forgot_password', to: 'auth#forgot_password'
        post 'reset_password', to: 'auth#reset_password'

        get 'profile', to: 'users#profile'
        patch 'profile', to: 'users#update_profile'

       # Reminder routes
       resources :reminders, only: [:index, :show, :create, :update, :destroy]

        # Notification routes
        resources :notifications, only: [:index, :show, :create, :update, :destroy] do
          member do
            patch :read
            patch :unread
          end
            collection do
            patch :read_all
          end
        end

        # Analytics routes
        get 'analytics', to: 'analytics#index'

        # Payments routes
        resources :payments, only: [:index] do
          collection do
            post 'upgrade'
            post 'webhook'
          end
        end

        # Admin routes
       namespace :admin do
         get 'dashboard', to: 'admin#dashboard'
         get 'users', to: 'admin#users'
         get 'properties', to: 'admin#all_properties'
       end
     end
   end
end