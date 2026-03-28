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
      get :player_presence
      get :recent_logs
      post :rcon_command
      get :startup_settings
      patch :update_startup_settings
      get :whitelist
      post :enable_whitelist
      post :disable_whitelist
      post :reload_whitelist
      post :add_whitelist_player
      delete :remove_whitelist_player
    end

    resources :members, controller: "server_members", only: %i[index create update destroy]
  end

  constraints DiscordBotNetworkConstraint.new do
    namespace :api do
      namespace :discord do
        namespace :bot do
          resources :servers, only: [] do
            member do
              post :status
              post :start
              post :stop
              post :restart
              post :sync
              post "startup-settings/show", action: :startup_settings_show
              post "startup-settings/update", action: :startup_settings_update
              post "whitelist/list", action: :whitelist_list
              post "whitelist/add", action: :whitelist_add
              post "whitelist/remove", action: :whitelist_remove
              post "whitelist/enable", action: :whitelist_enable
              post "whitelist/disable", action: :whitelist_disable
              post "whitelist/reload", action: :whitelist_reload
              post "rcon/command", action: :rcon_command
            end
          end
        end
      end
    end
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
