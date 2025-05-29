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
      resources :subscriptions, only: [:create]
      get 'subscriptions/success', to: 'subscriptions#success'
      get 'subscriptions/cancel', to: 'subscriptions#cancel'
      get 'subscriptions/status', to: 'subscriptions#status'
      put 'update_device_token', to: 'users#update_device_token'
      putt 'toggle_notifications', to: 'users#toggle_notifications'
      put 'update_profile_picture', to: 'users#update_profile_picture'
      delete 'remove_profile_picture', to: 'users#remove_profile_picture'
    end
  end
end