# -*- encoding : utf-8 -*-
Olook::Application.routes.draw do
  get "index/index"
  root :to => "home#index"

  match "/bem_vinda", :to => "pages#welcome", :as => "welcome"
  match "/sobre", :to => "pages#about", :as => "about"
  match "/termos", :to => "pages#terms", :as => "terms"
  match "/faq", :to => "pages#faq", :as => "faq"
  match "/privacidade", :to => "pages#privacy", :as => "privacy"

  resource :survey, :only => [:new, :create], :path => 'quiz', :controller => :survey
  resources :payments, :path => 'pagamento', :controller => :payments
  resources :addresses, :path => 'endereco', :controller => :addresses

  post "/add_to_cart" => "product#add_to_cart", :as => "add_to_cart"
  get "/produto/:id" => "product#index", :as => "product"
  get "membro/convite" => "members#invite", :as => 'member_invite'
  get "convite/(:invite_token)" => 'members#accept_invitation', :as => "accept_invitation"
  post "membro/convite_por_email" => 'members#invite_by_email', :as => 'member_invite_by_email'

  get "membro/importar_contatos" => "members#import_contacts", :as => 'member_import_contacts'
  post "membro/importar_contatos" => 'members#show_imported_contacts', :as => 'member_show_imported_contacts'

  post "membro/convidar_contatos" => "members#invite_imported_contacts", :as => 'member_invite_imported_contacts'
  get "membro/convidadas" => "members#invite_list", :as => 'member_invite_list'
  get "membro/como-funciona", :to => "members#how_to", :as => "member_how_to"

  namespace :admin do
    match "/", :to => "index#dashboard"

    resources :products do
      resources :pictures
      resources :details
      resources :variants
      member do
        post 'add_related' => "products#add_related", :as => "add_related"
        delete 'remove_related/:related_product_id' => "products#remove_related", :as => "remove_related"
      end
    end

    resources :users, :except => [:create, :new, :destroy] do
      collection do
        get 'export' => 'users#export', :as => 'export'
      end
    end
  end

  devise_for :admins, :controllers => { :registrations => "registrations", :sessions => "sessions" } do
    post "after_sign_in_path_for", :to => "sessions#after_sign_in_path_for", :as => "after_sign_in_path_for_session"
  end

  devise_for :users, :controllers => { :omniauth_callbacks => "omniauth_callbacks", :registrations => "registrations", :sessions => "sessions" } do
    get '/users/auth/:provider' => 'omniauth_callbacks#passthru'
    post "after_sign_in_path_for", :to => "sessions#after_sign_in_path_for", :as => "after_sign_in_path_for_session"
  end
end
