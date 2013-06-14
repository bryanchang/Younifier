Younifier::Application.routes.draw do

  get "/signin" => "services#signin"
  get "/signout" => "services#signout"

  get '/auth/:service/callback' => 'services#create'
  get '/auth/failure' => 'services#failure'
  get '/auth/:service/callback?oauth_problem=user_refused' => 'services#failure'
  get '/update_location' => 'services#update_location'

  resources :services, :only => [:index, :create, :destroy] do
    collection do
      get 'signin'
      get 'signout'
      get 'signup'
      post 'newaccount'
      get 'failure'
    end
  end

  # used for the demo application only
  resources :users, :only => [:index] do
    collection do
      get 'test'
    end
  end

  root :to => "users#index"

end
