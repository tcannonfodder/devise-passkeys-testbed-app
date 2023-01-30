Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/passkey_sessions'
  }

  get 'sign_up/new_challenge', to: 'users/registrations#new_challenge', as: :new_user_registration_challenge


  root "root#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
