Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users, controllers: {
    sessions: "users/sessions",   
    registrations: "users/registrations"
  }
  namespace :api do
    namespace :v1 do
      resources :movies, only: [:index, :show, :create, :update, :destroy]
      resource :subscription, only: [:create, :show, :update, :destroy]
      get 'current_user', to: 'users#current'
      post 'update_device_token', to: 'users#update_device_token'
      post 'toggle_notifications', to: 'users#toggle_notifications'
    end
  end
end

