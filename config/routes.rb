require 'resque/server'

# -*- encoding : utf-8 -*-
Olook::Application.routes.draw do

  get "beta/index"

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :newsletter, only: [:create]
      resources :product_interest, only: [:create]
      resources :freights, only: [:index]
      resources :payment_types, only: [:index]
      resources :addresses
      resource :current_cart, only: [:show, :update]
      resources :zip_code,only: [:show]
    end 
  end

  get "/modal", to: "modal#show", as: "modal"
  get "/sitemap", to: "sitemap#index", as: "sitemap"

  resources :wished_products, only: [:create, :destroy]

  get "/wishlist", to: 'wishlist#show', as: 'wishlist'

  get "/revenda/confirmacao", to: 'reseller#show', as: 'reseller_show'
  post "/revenda", to: "reseller#create", as: 'reseller_create'
  get "/revenda", to: "reseller#new", as: 'reseller_new'

  resources :live_feeds, path: "api", only: [:create, :index]

  resources :mercado_pago, only: [:create]

  get '/api/prices' => 'prices#index', as: 'api_prices'


  get "/stylequiz", to: "quiz#new", as: "wysquiz"

  get "/quiz", to: "quiz#new"
  get "/quiz/new", to: "quiz#new"

  post "/stylequiz", to: "quiz#create", as: 'wysquiz'
  get "/cadastro-stylequiz", to: 'join#new', as: 'join'
  post "/cadastro-stylequiz", to: 'join#register', as: 'join'
  put '/cadastro-stylequiz', to: 'join#login', as: 'join'
  post '/cadastro-stylequiz/facebook_login' => "join#facebook_login", as: 'facebook_login'
  get "/meu-estilo", to: "profiles#show", as: 'profile'

  mount Resque::Server => "/admin/resque"

  #temp redirect
  match '/colecoes/promodavez' => redirect('/colecoes/liquida_final')

  # rotas temporarias para marcas
  {
    "olook" => "Olook",
    "olookconcept" => "Olook Concept",
    "essential" => "Olook Essential",
    "botswana" => "botswana",
    "cocacola-clothing" => "Coca Cola Clothing",
    "colcci" => "Colcci",
    "douglas-harris" => "Douglas Harris",
    "ecletic" => "Eclectic",
    "espaco-fashion" => "Espaco Fashion",
    "forum" => "Forum",
    "iodice" => "Iodice",
    "juliana-jabour" => "Juliana Jabour",
    "juliana-manzini" => "Juliana Manzini",
    "leeloo" => "Leeloo",
    "mandi" => "Mandi",
    "mercatto" => "Mercatto",
    "m-officer" => "M Officer",
    "olli" => "Olli",
    "shop-126" => "Shop 126",
    "thelure" => "Thelure",
    "triton" => "Triton"
  }.each do |collection_name, brand|
    get "/colecoes/#{collection_name}" => redirect("/marcas/#{URI.encode(brand)}")
  end


  get "/colecoes/liquida_final", to: "collection_themes#show", defaults: {collection_theme: 'sale'}

  #temp route to fix a wrong email
  match "/olook-no-qbazar" => redirect("http://www.olook.com.br/stylist-news/olook-no-qbazar/")

  # temp route to fix sent emails
  # get "/olooklet(/*id)", to: "collection_themes#show", defaults: {collection_theme: 'sale'}
  get "/colecoes/irresistiveis_inverno", to: "collection_themes#show", defaults: {collection_theme: 'sale'}

  root :to => "home#index"
  get "/quiz", :to => "home#index"
  get "home/index"
  get "index/index"

  # Search Lab
  get "/busca/product_suggestions", :to => "search#product_suggestions", :as => "search_index"
  match "/busca(/*parameters)", :to => "search#show", :as => "search"

  # match "/busca", :to => "search#show", :as => "search"

  match '/404', :to => "application#render_public_exception"
  match '/500', :to => "application#render_public_exception"
  match "/home", :to => "home#index"
  match "/nossa-essencia", :to => "pages#our_essence", :as => "our_essence"
  match "/responsabilidade-social" => "pages#avc_campaign", :as => "responsabilidade_social"

  #match "/1anomuito" => "pages#um_ano_muito", :as => "um_ano_muito"
  match "/1anomuito", :to => "pages#how_to", :as => "how_to"

  #match "/sobre", :to => "pages#about", :as => "about"
  match "/termos", :to => "pages#terms", :as => "terms"
  match "/duvidasfrequentes", :to => "pages#faq", :as => "duvidasfrequentes"
  match "/centraldeatendimento", :to => "pages#faq", :as => "duvidasfrequentes"
  match "/afiliados", :to => "pages#faq", :as => "afiliados"
  match "/devolucoes", :to => "pages#faq", :as => "return_policy"
  match "/privacidade", :to => "pages#faq", :as => "privacy"
  match "/prazo-de-entrega", :to => "pages#delivery_time", :as => "delivery_time"
  match "/como-funciona", :to => "pages#how_to", :as => "how_to"
  match "/stylists/helena-linhares", :to => "stylists#helena_linhares", :as => "helena_linhares"
  get   "/contato" => "pages#contact", :as => "contact"
  post  "/contato" => "pages#send_contact", :as => "send_contact"
  match "/fidelidade", :to => "pages#loyalty", :as => "loyalty"
  match "/olookmovel", to: "pages#olookmovel", as: "olookmovel"
  match "/troca_e_devolucao", to: "pages#troca", as: "troca"
  match "/half_newsletter", to: "landing_pages#half_newsletter", as: "newsletter"
  match "/faq", :to => "pages#faq", :as => "faq"

  # TODO use clippings when press page change
  match "/olook-na-imprensa", :to => "clippings#index", :as => "press"
  #match "/olook-na-imprensa", :to => "pages#press", :as => "press"

  # BRANDS
  match "/marcas", :to => "brands#index", :as => "new_brands"

  match  "/marcas/:brand/nao-encontrado", to: "brands#not_found", as: 'brand_not_found'
  match "/marcas/:brand(/*parameters)", :to => "brands#show", as: "brand"

  #NEW OLOOKLET
  get "/olooklet/nao-encontrado" => "list_products/olooklet#not_found", :as => "olooklet_not_found"
  get "/olooklet(/*parameters)" => "list_products/olooklet#index", :as => "olooklet"
  get "/selecoes/nao-encontrado" => "list_products/selections#not_found", :as => "selections_not_found"
  get "/selecoes(/*parameters)" => "list_products/selections#index", :as => "selections"
  get "/novidades/nao-encontrado" => "list_products/newest_products#not_found", :as => "newest_not_found"
  get "/novidades(/*parameters)" => "list_products/newest_products#index", as: "newest"

  #NEW COLLECTIONS
  get '/colecoes', to: "collection_themes#index", as: "collection_themes"

  match "/colecoes/:collection_theme/nao-encontrado", to: "collection_themes#not_found", as: 'collection_theme_not_found'
  get '/colecoes/:collection_theme(/*parameters)', to: "collection_themes#show", as: "collection_theme"

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
  match "/topster" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/topster_data.xml")
  match "/nextperformance" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/nextperformance_data.xml")  
  match "/criteo" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/criteo_data.xml")
  match "/triggit" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/triggit_data.xml")
  match "/sociomantic" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/sociomantic_data.xml")
  match "/nano_interactive" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/nano_interactive_data.xml")
  match "/zanox" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/zanox_data.xml")
  match "/rise" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/rise_data.xml")
  match "/myestilo" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/myestilo_data.xml")
  match "/zoom" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/zoom_data.xml")
  match "/afilio" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/afilio_data.xml")
  match "/mt_performance" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/mt_performance_data.xml")
  match "/netaffiliation" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/netaffiliation_data.xml")
  match "/google_shopping" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/google_shopping_data.xml")
  match "/h2h" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/h2h_data.xml")
  match "/muccashop" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/muccashop_data.xml")
  match "/shopear" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/shopear_data.xml")
  match "/melt" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/melt_data.xml")
  match "/stylight" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/stylight_data.xml") 
  match "/ingriffe" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/ingriffe_data.xml") 
  match "/all_in" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/all_in_data.xml") 
  match "/buscape" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/buscape_data.xml") 
  
  # template da ilove_ecommerce
  match "/parceirosmkt" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/parceirosmkt_data.xml") 
  match "/ilove_ecommerce" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/ilove_ecommerce_data.xml") 
  match "/paraiso_feminino" => redirect("https://s3.amazonaws.com/#{ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'}/xml/paraiso_feminino_data.xml") 
  

  #SURVEY
  resource :survey, :only => [:new, :create], :path => 'quiz', :controller => :survey
  get "/survey/check_date", :to => "survey#check_date", :as => "check_date"

  #PRODUCT
  get "/produto/:id" => "product#show", :as => "product"
  get "/produto/:id/spy" => "product#spy", as: 'spy_product'
  post "/produto/share" => "product#share_by_email", as: 'product_share_by_email'

  #VITRINE / INVITE
  get "convite/(:invite_token)" => 'members#accept_invitation', :as => "accept_invitation"
  post "membro/convite_por_email" => 'members#invite_by_email', :as => 'member_invite_by_email'
  post "membro/novo_usuario_convite_por_email" => 'members#new_member_invite_by_email', :as => 'new_member_invite_by_email'
  get "membro/importar_contatos" => "members#import_contacts", :as => 'member_import_contacts'
  post "membro/importar_contatos" => 'members#show_imported_contacts', :as => 'member_show_imported_contacts'
  post "membro/convidar_contatos" => "members#invite_imported_contacts", :as => 'member_invite_imported_contacts'
  get "membro/convidadas" => "members#invite_list", :as => 'member_invite_list'
  get "membro/vitrine" => redirect('/minha/vitrine')
  get "/vitrines", to:"members#half_showroom", as: 'half_showroom'
  get "/criar/vitrine", to: 'join#showroom', as: 'join_showroom'
  get "membro/bem-vinda", :to => "members#welcome", :as => "member_welcome"
  get "membro/ganhe-creditos", :to => "members#earn_credits", :as => "member_earn_credits"
  #get "membro/creditos", :to => "members#credits", :as => "member_credits"


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

  resources :ping, :only => [:index]
  resources :shippings, :only => [:show]
  get '/shipping_updated_freight_table/:id' => 'shippings#show', defaults: {freight_service_ids: "4,5"}

  #ADMIN
  devise_for :admins

  namespace :admin do
    resources :integrations

    get "/", :to => "dashboard#index"
    get "/lista_pastas_s3", to: "bucket_s3#index"

    resources :headers
    resources :seo_links
    resources :product_interests, only: [:index]

    resources :clippings
    get "ses" => "simple_email_service_infos#index", as: "ses"
    match "/ses_info", :to => "simple_email_service_infos#show", :as => "ses_info"

    namespace :orders do
      resources :deliveries
      resources :statuses
    end
    resources :billet_reports, only: :index
    resources :newest_reports, only: :index

    get 'product_autocomplete' => 'products#autocomplete_information'
    get 'pictures_process' => 'pictures_process#index', as: 'pictures_process'
    post 'pictures_process' => 'pictures_process#create'
    resources :products do
      collection do
        post 'sync_products' => 'products#sync_products', :as => 'sync_products'
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

    # reports
    resources :reports

    resources :collection_theme_groups
    resources :collection_themes do
      collection do
        get 'import' => "collection_themes#import", :as => "import_index"
        post 'import_create'
      end
    end
    resources :highlights
    resources :highlight_campaigns
    resources :brands

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
    resources :resellers, :except => [:create, :new] do

    end

    resources :utilities do
      collection do
        post 'restart_resque_workers' => "utilities#restart_resque_workers", :as => "restart_resque_workers"
        post 'invalidates_cdn_content' => "utilities#invalidates_cdn_content", :as => "invalidates_cdn_content"
      end
    end
    resources :shipping_services

    put 'shipping_policies' => 'shipping_policies#update'
    put 'shippings' => 'shippings#update'

    resources :collections do
      get 'mark_all_products_as_visible' => 'collections#mark_all_products_as_visible', as: 'display_products'
      get 'mark_all_products_as_invisible' => 'collections#mark_all_products_as_invisible', as: 'hide_products'
      post "mark_specific_products_as_visible" => "collections#mark_specific_products_as_visible", :as => "mark_specific_products_as_visible"
    end

    post 'integrate_orders' => "orders#integrate_orders"
    post 'integrate_cancel' => "orders#integrate_cancel"
    post 'integrate_payment' => "orders#integrate_payment"

    resources :orders do
      member do
        post 'authorize_payment'
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
      member do
        post 'copy'
      end
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
    resource :mkt_settings

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

    get "billet_batch/new", as: :new_billet_batch

    post "billet_batch/create", as: :create_billet_batch

    get "visibility_batch/new", as: :new_visibility_batch

    get "visibility_batch/export", as: :export_visibility_batch_to_csv

    post "visibility_batch/create", as: :create_visibility_batch
    get "visibility_batch/commit", as: :commit_visibility_batch
    get "visibility_batch/confirmation", as: :confirmation_visibility_batch


    get "html_generator/index", as: :html_generators
    post "html_generator/create", as: :create_html_generator

    resources :itineraries
  end

  #USER / SIGN IN

  devise_for :users, :path => 'conta', :controllers => { :omniauth_callbacks => "omniauth_callbacks", :registrations => "users/registrations", :sessions => "users/sessions" } do
    get '/entrar/:id' => 'users/sessions#new', :as => :new_user_session
    post '/entrar' => 'users/sessions#create', :as => :user_session
    delete '/logout' => 'users/sessions#destroy', :as => :destroy_user_session
    get '/registrar' => "users/registrations#new_half", :as => :new_half_user_session
    post '/registrar' => "users/registrations#create_half", :as => :create_half_user
    post '/facebook_connect' => "users/facebook_connect#create", :as => :facebook_connect
    get '/users/auth/:provider' => 'omniauth_callbacks#passthru' # TODO change to "conta" instead of user
    delete '/conta/remover_facebook' => 'users/registrations#destroy_facebook_account', :as => :destroy_facebook_account
    match '/conta/auth/facebook/setup', :to => 'omniauth_callbacks#setup'
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

  match 'campaign_email_subscribe', to: "campaign_emails#subscribe", as: :subscribe_campaign_email

  #CHECKOUT
  resource :cart, :path => 'sacola', :controller => "cart/cart", :except => [:create] do
    get 'i_want_freebie' => 'cart/cart#i_want_freebie', as: 'i_want_freebie'
    resources :items, :to => 'cart/items'
    resources :look_items, to: 'cart/look_items', only: [:create, :destroy]
  end
  # => Used by chaordic
  put 'sacola/:cart_id' => 'cart/cart#add_variants', as: :add_variants

  resource :checkout, :path => 'pagamento', :controller => 'checkout/checkout' do
    get "/", :to => "checkout/checkout#new"
    put "/", to: 'checkout/checkout#update'
    get "/novo", :to => "checkout/checkout#new", defaults: {freight_service_ids: "4,5"}
    get "preview_by_zipcode", :to => "checkout/addresses#preview", :as => :preview_zipcode
    resources :addresses, :path => 'endereco', :controller => "checkout/addresses"
    resources :login, :path=> "login", :controller => "checkout/login", :only => [:index]
    resources :billets, path: "boletos", :controller => "checkout/billets", only: [:show]
  end

  #FINISH
  get '/pedido/:number', :to =>'checkout/orders#show', :as => :order_show

  #MOIP-CALLBACK
  post '/moip', :to => 'checkout/payment_callbacks#create_moip', :as => :payment

  get '/ceps/:cep' => 'ceps#show', as: 'cep'
  #ZIPCODE
  get "/get_address_by_zipcode", :to => "zipcode_lookup#get_address_by_zipcode"
  post "/address_data", :to => "zipcode_lookup#address_data"

  #FREIGHT
  post "freight_price", :to => "freight_lookup#show"

  get '/l/:page_url', :controller =>'landing_pages', :action => 'show' , :as => 'landing'
  get '/diadasmaes' , :controller =>'landing_pages', :action => 'mother_day' , :as => 'mother_day'
  get "/cadastro", :to => "landing_pages#show", defaults: { page_url: 'cadastro', ab_t: 1 }
  get "/cadastro/olookmovel", :to => "landing_pages#olookmovel", as: 'olookmovel_lp'
  post "/cadastro/olookmovel", :to => "landing_pages#create_olookmovel", as: 'olookmovel_lp'
  get "/cadastro_parcerias", :to => "landing_pages#show", defaults: { page_url: 'cadastro', ab_t: nil, partner: "adlead" }

  # Friendly urls (ok, I know it is not the best approach...)
  match '/sapatos' => redirect('/sapato'), as: 'shoes'
  match '/sneaker' => redirect('/sapato/sneaker'), as: 'sneakers'
  match '/rasteira' => redirect('/sapato/rasteira'), as: 'rasteiras'
  # plural
  match '/sneakers' => redirect('/sapato/sneaker'), as: 'sneakers'
  match '/rasteiras' => redirect('/sapato/rasterira'), as: 'rasteiras'
  match '/sapatilhas' => redirect('/sapato/slipper-sapatilha'), as: 'sapatilhas'
  match '/slippers' => redirect('/sapato/slipper-sapatilha'), as: 'slippers'
  match '/sandalias' => redirect('/sapato/sandalia'), as: 'sandalias'
  match '/scarpins' => redirect('/sapato/scarpin'), as: 'scarpins'
  match '/anabelas' => redirect('/sapato/anabela'), as: 'anabelas'

  match '/bolsas' => redirect('/bolsa'), as: 'bags'
  match '/acessorios' => redirect('/acessorio'), as: 'accessories'
  match '/oculos' => redirect('/acessorio/oculos%20de%20sol'), as: 'glasses'
  match '/roupas' => redirect('/roupa'), as: 'clothes'
  match '/novas-marcas' => redirect('/roupa/colcci-douglas%20harris-eclectic-espaco%20fashion-forum-iodice-olli-shop%20126-thelure-triton'), as: 'brands'
  match '/acessorios-sapatos' => redirect('/sapato/conforto-amaciante-apoio%20plantar-impermeabilizante-palmilha-protecao%20para%20calcanhar'), as: 'shoe_accessories'

  mount Split::Dashboard, :at => 'split'

  # Produto
  get "/:id", to: "product#show", id: /[\w|-]*\d+/, as: "product_seo"

  # CATALOGO
  match "/catalogo/:category(/*parameters)", to: "catalogs#index"
  match  "/:category/nao-encontrado", to: "catalogs#not_found", as: 'catalog_not_found'
  match "/:category(/*parameters)", to: "catalogs#index", as: "catalog", constraints: { category: /(?:sapato|roupa|acessorio|bolsa|curves)/i, format: 'html' }

  get '*custom_url' => 'custom_url#show'

end



