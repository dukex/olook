require 'resque/server'

# -*- encoding : utf-8 -*-
Olook::Application.routes.draw do

  mount Resque::Server => "/admin/resque"

  root :to => "home#index"
  get "/quiz", :to => "home#index"
  get "home/index"
  get "index/index"

  match '/404', :to => "application#render_public_exception"
  match '/500', :to => "application#render_public_exception"
  match "/home", :to => "home#index"
  match "/nossa-essencia", :to => "pages#our_essence", :as => "our_essence"
  match "/responsabilidade-social" => "pages#avc_campaign", :as => "responsabilidade_social"

  match "/1anomuito" => "pages#um_ano_muito", :as => "um_ano_muito"

  #match "/sobre", :to => "pages#about", :as => "about"
  match "/termos", :to => "pages#terms", :as => "terms"
  match "/duvidasfrequentes", :to => "pages#faq", :as => "duvidasfrequentes"
  match "/centraldeatendimento", :to => "pages#faq", :as => "duvidasfrequentes"
  match "/devolucoes", :to => "pages#return_policy", :as => "return_policy"
  match "/privacidade", :to => "pages#privacy", :as => "privacy"
  match "/prazo-de-entrega", :to => "pages#delivery_time", :as => "delivery_time"
  match "/como-funciona", :to => "pages#how_to", :as => "how_to"
  match "/olook-na-imprensa", :to => "pages#press", :as => "press"
  match "/stylists/helena-linhares", :to => "stylists#helena_linhares", :as => "helena_linhares"
  get   "/contato" => "pages#contact", :as => "contact"
  post  "/contato" => "pages#send_contact", :as => "send_contact"
  match "/fidelidade", :to => "pages#loyalty", :as => "loyalty"
  match "/festas", :to => "moments#show", :as => "festas", :defaults => {:id => 4}
  match "/olookmovel", to: "pages#olookmovel", as: "olookmovel"

  #LOOKBOOKS
  match "/tendencias/:name", :to => "lookbooks#show", :as => "lookbook"
  match "/tendencias", :to => "lookbooks#index", :as => "lookbooks"


  #LIQUIDATIONS
  get "/olooklet/:id" => "liquidations#show", :as => "liquidations"
  get '/update_liquidation', :to => "liquidations#update", :as => "update_liquidation"
  match "/promododia" , :to => "liquidations#index", :as => "promododia"
  match "/olooklet" , :to => "liquidations#index", :as => "olooklet"

  #NEW COLLECTIONS
  get '/colecoes', to: "collection_themes#index", as: "collection_themes"
  get '/colecoes/*slug', to: "collection_themes#show", as: "collection_theme"

  # NEW COLLECTIONS - TODO
  get '/update_moment', to: "moments#update", as: "update_moment"

  # Friendly urls (ok, I know it is not the best approach...)
  match '/sapatos', to: "moments#show", as: "shoes", :defaults => {:category_id => Category::SHOE, :id => 1}
  match '/sneaker', to: "moments#show", as: "sneakers", :defaults => {:category_id => Category::SHOE, :id => 1, :shoe_subcategories => ["sneaker"]}
  match '/rasteira', to: "moments#show", as: "rasteiras", :defaults => {:category_id => Category::SHOE, :id => 1, :shoe_subcategories => ["rasteira"]}
  # plural
  match '/sneakers', to: "moments#show", as: "sneakers", :defaults => {:category_id => Category::SHOE, :id => 1, :shoe_subcategories => ["sneaker"]}
  match '/rasteiras', to: "moments#show", as: "rasteiras", :defaults => {:category_id => Category::SHOE, :id => 1, :shoe_subcategories => ["rasteira"]}
  match '/sapatilhas', to: "moments#show", as: "sapatilhas", :defaults => {:category_id => Category::SHOE, :id => 1, :shoe_subcategories => ["sapatilha"]}
  match '/slippers', to: "moments#show", as: "slippers", :defaults => {:category_id => Category::SHOE, :id => 1, :shoe_subcategories => ["slipper"]}
  match '/sandalias', to: "moments#show", as: "sandalias", :defaults => {:category_id => Category::SHOE, :id => 1, :shoe_subcategories => ["sandalia"]}
  match '/scarpins', to: "moments#show", as: "scarpins", :defaults => {:category_id => Category::SHOE, :id => 1, :shoe_subcategories => ["scarpin"]}
  match '/anabelas', to: "moments#show", as: "anabelas", :defaults => {:category_id => Category::SHOE, :id => 1, :shoe_subcategories => ["anabela"]}

  match '/bolsas', to: "moments#show", as: "bags", :defaults => {:category_id => Category::BAG, :id => 1}
  match '/acessorios', to: "moments#show", as: "accessories", :defaults => {:category_id => Category::ACCESSORY, :id => 1}
  match '/oculos', to: "moments#glasses", as: "glasses", :defaults => {:category_id => Category::ACCESSORY, :accessory_subcategories=>["oculos-de-sol"], :id => 1}
  match '/roupas', to: "moments#clothes", as: "clothes", :defaults => {:category_id => Category::CLOTH, :id => 1}


  #FRIENDS
  match "/membro/:share/:uid", :to => "home#index"
  match "/minhas-amigas/conectar", :to => "friends#facebook_connect", :as => "facebook_connect"
  match "/minhas-amigas/home", :to => "friends#home", :as => "friends_home"
  match "/minhas-amigas/vitrine/:friend_id", :to => "friends#showroom", :as => "friend_showroom"
  get "/minhas-amigas/atualizar-lista-amigas", :to => "friends#update_friends_list", :as => "update_friends_list"
  get "/minhas-amigas/atualizar-quiz", :to => "friends#update_survey_question", :as => "update_survey_question"
  post "/postar-no-mural", :to => "friends#post_wall", :as => "post_wall"
  post "/postar-resposta-quiz", :to => "friends#post_survey_answer", :as => "post_survey_answer"
  post "/postar-convite", :to => "friends#post_invite", :as => "post_invite"

  #XML FOR STATISTICS
  match "/triggit", :to => "xml#triggit", :as => "triggit", :defaults => { :format => 'xml' }
  match "/zanox", :to => "xml#zanox", :as => "zanox", :defaults => { :format => 'xml' }
  match "/sociomantic", :to => "xml#sociomantic", :as => "sociomantic", :defaults => { :format => 'xml' }
  match "/criteo", :to => "xml#criteo", :as => "criteo", :defaults => { :format => 'xml' }
  match "/mt_performance", :to => "xml#mt_performance", :as => "mt_performance", :defaults => { :format => 'xml' }
  match "/click_a_porter", :to => "xml#click_a_porter", :as => "click_a_porter", :defaults => { :format => 'xml' }
  match "/topster" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/topster_data.xml")
  match "/ilove_ecommerce", :to => "xml#ilove_ecommerce", :as => "ilove_ecommerce", :defaults => { :format => 'xml' }
  match "/zoom", :to => "xml#zoom", :as => "zoom", :defaults => { :format => 'xml' }
  match "/netaffiliation", :to => "xml#netaffiliation", :as => "netaffiliation", :defaults => { :format => 'xml' }
  match "/shopping_uol", :to => "xml#shopping_uol", :as => "shopping_uol", :defaults => { :format => 'xml' }
  match "/google_shopping", :to => "xml#google_shopping", :as => "google_shopping", :defaults => { :format => 'xml' }
  match "/buscape", :to => "xml#buscape", :as => "buscape", :defaults => { :format => 'xml' }
  match "/kelkoo", :to => "xml#kelkoo", :as => "kelkoo", :defaults => { :format => 'xml' }
  match "/kuanto_kusta", :to => "xml#kuanto_kusta", :as => "kuanto_kusta", :defaults => { :format => 'xml' }
  match "/nextperformance", :to => "xml#nextperformance", :as => "nextperformance", :defaults => { :format => 'xml' }

  #SURVEY
  resource :survey, :only => [:new, :create], :path => 'quiz', :controller => :survey
  get "/survey/check_date", :to => "survey#check_date", :as => "check_date"

  #PRODUCT
  get "/produto/:id" => "product#show", :as => "product"
  post "/produto/share" => "product#share_by_email", as: 'product_share_by_email'

  #VITRINE / INVITE
  get "membro/convite" => "members#invite", :as => 'member_invite'
  get "convite/(:invite_token)" => 'members#accept_invitation', :as => "accept_invitation"
  post "membro/convite_por_email" => 'members#invite_by_email', :as => 'member_invite_by_email'
  post "membro/novo_usuario_convite_por_email" => 'members#new_member_invite_by_email', :as => 'new_member_invite_by_email'
  get "membro/importar_contatos" => "members#import_contacts", :as => 'member_import_contacts'
  post "membro/importar_contatos" => 'members#show_imported_contacts', :as => 'member_show_imported_contacts'
  post "membro/convidar_contatos" => "members#invite_imported_contacts", :as => 'member_invite_imported_contacts'
  get "membro/convidadas" => "members#invite_list", :as => 'member_invite_list'
  get "membro/vitrine", :to => "members#showroom", :as => "member_showroom"
  get "membro/vitrine_roupas", :to => "members#showroom_clothes", :as => "member_showroom_clothes"
  get "membro/vitrine_shoes", :to => "members#showroom_shoes", :as => "member_showroom_shoes"
  get "membro/vitrine_bags", :to => "members#showroom_bags", :as => "member_showroom_bags"
  get "membro/vitrine_accessories", :to => "members#showroom_accessories", :as => "member_showroom_accessories"
  get "membro/bem-vinda", :to => "members#welcome", :as => "member_welcome"
  get "membro/ganhe-creditos", :to => "members#earn_credits", :as => "member_earn_credits"
  #get "membro/creditos", :to => "members#credits", :as => "member_credits"
  post "user_liquidations", :controller => "user_liquidations", :action => "update"
  post "user_notifications", :controller => "user_liquidations", :action => "notification_update"

  # GIFT
  namespace :gift, :path => "presentes" do
    root :to => "home#index"
    get "update_birthdays_by_month/:month" => "home#update_birthdays_by_month"
    get "helena_tips" => "home#helena_tips"
    get "top_five" => "home#top_five"
    get "hot_on_facebook" => "home#hot_on_facebook"
    resource :survey, :only => [:new, :create], :path => 'quiz', :controller => :survey
    resources :recipients do
      resources :suggestions, :only => [:index]
      post "suggestions/add_to_cart" => "suggestions#add_to_cart", :as => :add_suggestions_to_cart
      get "suggestions/select_gift/:product_id" => "suggestions#select_gift"
      post "suggestions/select_gift/" => "suggestions#select_gift"
      member do
        get :edit
        put :edit
        put :update
      end
    end
    resources :occasions, :only => [:new, :create] do
      collection do
        post "new_with_data" => "occasions#new_with_data"
      end
    end
    get "profiles/:name" => "profiles#show"
  end

  resources :shippings, :only => [:show]

  #ADMIN
  devise_for :admins

  namespace :admin do
    get "/", :to => "dashboard#index"

    namespace :orders do
      resources :deliveries
      resources :statuses
    end

    get 'product_autocomplete' => 'products#autocomplete_information'
    resources :products do
      collection do
        post 'sync_products' => 'products#sync_products', :as => 'sync_products'
        post "mark_specific_products_as_visible" => "products#mark_specific_products_as_visible", :as => "mark_specific_products_as_visible"
      end
      post 'sort_pictures' => 'pictures#sort', as: 'sort_pictures'

      resources :pictures do

        collection do
          get  'multiple_pictures' => 'pictures#new_multiple_pictures', :as => 'new_multiple_pictures'
          post 'multiple_pictures' => 'pictures#create_multiple_pictures', :as => 'create_multiple_pictures'
        end
      end
      resources :details
      resources :variants
      member do
        post 'add_related' => "products#add_related", :as => "add_related"
        post 'add_freebie' => "products#add_freebie", :as => "add_freebie"
        delete 'remove_related/:related_product_id' => "products#remove_related", :as => "remove_related"
        delete 'remove_freebie/:freebie_id' => "products#remove_freebie", :as => "remove_freebie"
      end
    end

    resources :lookbooks do
      resources :images do
        resources :lookbook_image_maps
      end
      get :products, :to => "lookbooks#product"
    end

    resources :collection_theme_groups

    resources :collection_themes

    resources :users, :except => [:create, :new] do
      collection do
        get 'statistics' => 'users#statistics', :as => 'statistics'
        get 'export' => 'users#export', :as => 'export'
        get 'login/:id' => 'users#admin_login'
        get 'lock_access/:id' => 'users#lock_access'
        get 'unlock_access/:id' => 'users#unlock_access'
        post 'create_credit_transaction' => 'users#create_credit_transaction'
      end
    end

    resources :utilities do
      collection do
        post 'restart_resque_workers' => "utilities#restart_resque_workers", :as => "restart_resque_workers"
        post 'invalidates_cdn_content' => "utilities#invalidates_cdn_content", :as => "invalidates_cdn_content"
      end
    end
    resources :shipping_services
    resources :collections do
      get 'mark_all_products_as_visible' => 'collections#mark_all_products_as_visible', as: 'display_products'
      get 'mark_all_products_as_invisible' => 'collections#mark_all_products_as_invisible', as: 'hide_products'
    end

    post 'integrate_orders' => "orders#integrate_orders"
    post 'integrate_cancel' => "orders#integrate_cancel"
    post 'integrate_payment' => "orders#integrate_payment"

    resources :orders do
      member do
        post 'change_state'
        post 'remove_loyalty_credits'
      end

      collection do
        get 'timeline/:id' => 'orders#generate_purchase_timeline'
      end

    end
    resources :coupons, :except => [:destroy]
    resources :holidays
    resources :landing_pages
    resources :promotions
    resources :liquidations do
      resources :liquidation_carousels, :as => "carousels" do
        collection do
          put "/" => "liquidation_carousels#update"
        end
      end
      get 'fetch' => "liquidations#fetch", :as => "fetch"
      resources :liquidation_carousels, :as => "carousels"
      resources :liquidation_products, :as => "products"
    end
    resources :roles do
      resources :permissions
    end
    resources :admins

    resources :gift_occasion_types
    resources :gift_recipient_relations

    scope 'credits' do
      root :to => 'order_credits#index', :as => :credits
      resources :order_credits, :only => :index
    end

    resources :campaigns

    resource :settings

    resources :moip_callbacks do
      member do
        post 'change_to_processed'
        post 'change_to_not_processed'
      end
    end

    resources :braspag_authorize_responses do
      member do
        post 'change_to_processed'
        post 'change_to_not_processed'
      end
    end

    resources :braspag_capture_responses do
      member do
        post 'change_to_processed'
        post 'change_to_not_processed'
      end
    end

    resources :payments, :only => [:index, :show]

    resources :gift_boxes do
      get :products, :to => "gift_boxes#product"
    end

    get '/discounts' => 'discounts#index', as: :discounts

  end

  #USER / SIGN IN

  devise_for :users, :path => 'conta', :controllers => { :omniauth_callbacks => "omniauth_callbacks", :registrations => "users/registrations", :sessions => "users/sessions" } do
    get '/entrar' => 'users/sessions#new', :as => :new_user_session
    post '/entrar' => 'users/sessions#create', :as => :user_session
    delete '/logout' => 'users/sessions#destroy', :as => :destroy_user_session
    get '/registrar' => "users/registrations#new_half", :as => :new_half_user_session
    post '/registrar' => "users/registrations#create_half", :as => :create_half_user
    get '/users/auth/:provider' => 'omniauth_callbacks#passthru'
    delete '/conta/remover_facebook' => 'users/registrations#destroy_facebook_account', :as => :destroy_facebook_account
  end

  get '/conta/pedidos/:number', :controller =>'users/orders', :action => 'show' , :as => "user_order"
  namespace :users, :path => 'conta', :as => "user" do
    #get "/presentes", to: 'gifts#index', as: "gifts"

    resources :addresses, :path => 'enderecos'
    resources :orders, :path => 'pedidos', :only => [:index]
    resources :credits, :path => 'creditos' do
      collection do
        post 'creditos/reenviar_convite/:id' => 'credits#resubmit_invite', :as => :resubmit_invite
        post 'creditos/reenviar_todos' => 'credits#resubmit_all_invites', :as => :resubmit_all_invites
      end
    end
  end

  #TESTE A/B
  resources :campaign_emails do
    member do
      get 'login'
      get 'remembered'
    end
  end

  #CHECKOUT
  resource :cart, :path => 'sacola', :controller => "cart/cart", :except => [:create] do
    resources :items, :to => 'cart/items'
  end

  resource :checkout, :path => 'pagamento', :controller => 'checkout/checkout' do
    get "/", :to => "checkout/checkout#new"
    get "preview_by_zipcode", :to => "checkout/addresses#preview", :as => :preview_zipcode
    resources :addresses, :path => 'endereco', :controller => "checkout/addresses"
    resources :login, :path=> "login", :controller => "checkout/login", :only => [:index]
  end

  #FINISH
  get '/pedido/:number', :to =>'checkout/orders#show', :as => :order_show

  #MOIP-CALLBACK
  post '/moip', :to => 'checkout/payment_callbacks#create_moip', :as => :payment

  #ZIPCODE
  get "/get_address_by_zipcode", :to => "zipcode_lookup#get_address_by_zipcode"
  post "/address_data", :to => "zipcode_lookup#address_data"

  #FREIGHT
  post "freight_price", :to => "freight_lookup#show"

  get '/l/:page_url', :controller =>'landing_pages', :action => 'show' , :as => 'landing'
  get ":page_url", :to => "landing_pages#show"

end



