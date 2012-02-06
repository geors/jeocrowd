Jeocrowd4s::Application.routes.draw do
  resources :profiles do
    get 'activate', :on => :member
    get 'duplicate', :on => :member
  end

  resources :instances

  resources :searches, :except => [:edit]
  root :to => 'searches#index'
end
