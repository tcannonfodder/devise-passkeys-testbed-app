Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/passkey_sessions'
  }

  devise_scope :user do
    post 'sign_up/new_challenge', to: 'users/registrations#new_challenge', as: :new_user_registration_challenge
    post 'sign_in/new_challenge', to: 'users/passkey_sessions#new_challenge', as: :new_user_session_challenge

    post 'reauthenticate/new_challenge', to: 'users/passkey_reauthentication#new_challenge', as: :new_user_reauthentication_challenge
    post 'reauthenticate', to: 'users/passkey_reauthentication#reauthenticate', as: :user_reauthentication


    namespace :users do
      resources :passkeys, only: [:create, :destroy] do
        collection do
          post :new_create_challenge
        end

        member do
          post :new_destroy_challenge
        end
      end
    end
  end


  root "root#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
