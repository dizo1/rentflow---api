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
        resources :units, only: [:index, :create]
      end
      resources :units, only: [:show, :update, :destroy]
    end
  end
end
