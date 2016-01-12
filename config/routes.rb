Rails.application.routes.draw do
  resources :manifests, only: [:new]

  namespace :api do
    namespace :v0 do
      resources :tokens, only: [:create]
      resources :manifests, only: [] do
        resource :signature, only: [:create]
      end
      resources :manifests, only: [:create]
      resources :method_codes, only: [:index]
      patch 'manifests', to: 'manifests#update'
      get 'manifest', to: 'manifests#show'
      get 'manifests/search', to: 'manifests#search'
    end
  end

  require 'sidekiq/web'

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV['SIDEKIQ_USERNAME'] && password == ENV['SIDEKIQ_PASSWORD']
  end

  mount Sidekiq::Web => '/sidekiq'
end
