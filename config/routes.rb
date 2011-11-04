Jeocrowd4s::Application.routes.draw do
  resources :searches, :except => [:edit]
  root :to => 'searches#index'
end
