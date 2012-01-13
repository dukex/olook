# -*- encoding : utf-8 -*-
Olook::Application.routes.draw do
  get "index/index"
  root :to => "home#index"

  match "/bem_vinda", :to => "pages#welcome", :as => "welcome"
  match "/sobre", :to => "pages#about", :as => "about"
  match "/termos", :to => "pages#terms", :as => "terms"
  match "/faq", :to => "pages#faq", :as => "faq"
  match "/privacidade", :to => "pages#privacy", :as => "privacy"
  match "/prazo-de-entrega", :to => "pages#delivery_time", :as => "delivery_time"
  match "/como-funciona", :to => "pages#how_to", :as => "how_to"
  match "/imprensa", :to => "pages#press_release", :as => "press_release"
  match "/lookbooks/lets-party", :to => "lookbooks#lets_party", :as => "lets_party"
  match "/lookbooks/palha", :to => "lookbooks#palha", :as => "palha"
  match "/lookbooks/safari", :to => "lookbooks#safari", :as => "safari"
  get   "/contato" => "pages#contact", :as => "contact"
  post  "/contato" => "pages#send_contact", :as => "send_contact"

  get '/pedido/:number/boleto', :to =>'orders#billet', :as => "order_billet"
  get '/pedido/:number/credito', :to =>'orders#credit', :as => "order_credit"
  get '/pedido/:number/debito', :to =>'orders#debit', :as => "order_debit"

  resource :criteo, :only => [:show], :path => 'criteo', :controller => :criteo

  resource :survey, :only => [:new, :create], :path => 'quiz', :controller => :survey
  resources :payments, :path => 'pagamento', :controller => :payments
  resources :credit_cards, :only => [:new, :create], :path => 'credito', :controller => :credit_cards
  resources :debits, :only => [:new, :create], :path => 'debito', :controller => :debits
  resources :billets, :only => [:new, :create], :path => 'boleto', :controller => :billets
  resources :addresses, :path => 'endereco', :controller => :addresses
  resource :cart, :only => [:show, :create, :update, :destroy, :update_status], :path => 'sacola', :controller => :cart do
    collection do
      put "update_bonus" => "cart#update_bonus", :as => "update_bonus"
      delete "remove_bonus" => "cart#remove_bonus", :as => "remove_bonus"
      put "update_coupon" => "cart#update_coupon", :as => "update_coupon"
      put "update_quantity_product" => "cart#update_quantity_product", :as => "update_quantity_product"
    end
  end
  post "/assign_address", :to => "addresses#assign_address", :as => "assign_address"

  get "/produto/:id" => "product#show", :as => "product"
  get "membro/convite" => "members#invite", :as => 'member_invite'
  get "convite/(:invite_token)" => 'members#accept_invitation', :as => "accept_invitation"
  post "membro/convite_por_email" => 'members#invite_by_email', :as => 'member_invite_by_email'

  get "membro/importar_contatos" => "members#import_contacts", :as => 'member_import_contacts'
  post "membro/importar_contatos" => 'members#show_imported_contacts', :as => 'member_show_imported_contacts'

  post "membro/convidar_contatos" => "members#invite_imported_contacts", :as => 'member_invite_imported_contacts'
  get "membro/convidadas" => "members#invite_list", :as => 'member_invite_list'
  get "membro/vitrine", :to => "members#showroom", :as => "member_showroom"

  get '/conta/pedidos/:number', :controller =>'user/orders', :action => 'show' , :as => "user_order"

  get '/l/:page_url', :controller =>'landing_pages', :action => 'show' , :as => 'landing'

  namespace :user, :path => 'conta' do
    resources :users, :path => 'editar', :only => [:update]
    resources :addresses, :path => 'enderecos'
    resources :orders, :path => 'pedidos', :only => [:index]
    resources :credits, :path => 'creditos' do
      collection do
        post 'creditos/reenviar_convite/:id' => 'credits#resubmit_invite', :as => :resubmit_invite
        post 'creditos/reenviar_todos' => 'credits#resubmit_all_invites', :as => :resubmit_all_invites
      end
    end
  end

  namespace :admin do
    match "/", :to => "index#dashboard"

    resources :products do
      resources :pictures do
        collection do
          get  'multiple_pictures' => 'pictures#new_multiple_pictures', :as => 'new_multiple_pictures'
          post  'multiple_pictures' => 'pictures#create_multiple_pictures', :as => 'create_multiple_pictures'
        end
      end
      resources :details
      resources :variants
      member do
        post 'add_related' => "products#add_related", :as => "add_related"
        delete 'remove_related/:related_product_id' => "products#remove_related", :as => "remove_related"
      end
    end

    resources :users, :except => [:create, :new, :destroy] do
      collection do
        get 'statistics' => 'users#statistics', :as => 'statistics'
        get 'export' => 'users#export', :as => 'export'
      end
    end

    resources :utilities do
      collection do
        post 'restart_resque_workers' => "utilities#restart_resque_workers", :as => "restart_resque_workers"
        post 'invalidates_cdn_content' => "utilities#invalidates_cdn_content", :as => "invalidates_cdn_content"
      end
    end
    resources :shipping_services
    resources :collections
    resources :orders
    resources :coupons, :except => [:destroy]
    resources :landing_pages
  end

  devise_for :admins, :controllers => { :registrations => "registrations", :sessions => "sessions" } do
    post "after_sign_in_path_for", :to => "sessions#after_sign_in_path_for", :as => "after_sign_in_path_for_session"
  end

  devise_for :users, :controllers => { :omniauth_callbacks => "omniauth_callbacks", :registrations => "registrations", :sessions => "sessions" } do
    get '/entrar' => 'sessions#new', :as => :new_user_session
    post '/entrar' => 'sessions#create', :as => :user_session
    delete '/logout' => 'sessions#destroy', :as => :destroy_user_session
    get '/users/auth/:provider' => 'omniauth_callbacks#passthru'
    post "after_sign_in_path_for", :to => "sessions#after_sign_in_path_for", :as => "after_sign_in_path_for_session"
  end
end
