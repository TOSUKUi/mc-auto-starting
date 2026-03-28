Rails.application.routes.draw do
  get "discord/login", to: "discord_oauth#start", as: :discord_login
  get "auth/:provider/callback", to: "discord_oauth#callback"
  get "auth/failure", to: "discord_oauth#failure"
  get "invites/:token", to: "invites#show", as: :invite
  get "login", to: "sessions#new", as: :login
  delete "logout", to: "sessions#destroy", as: :logout
  resources :discord_invitations, path: "discord-invitations", only: %i[index create] do
    member do
      patch :revoke
    end
  end
  resources :servers, only: %i[index new create show destroy] do
    member do
      post :start
      post :stop
      post :restart
      post :sync
      post :repair_publication
    end

    resources :members, controller: "server_members", only: %i[index create update destroy]
  end
  root "servers#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
