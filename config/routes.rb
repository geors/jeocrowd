Jeocrowd4s::Application.routes.draw do
  resources :instances

  resources :searches, :except => [:edit]
  root :to => 'searches#index'
end
