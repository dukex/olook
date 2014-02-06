# -*- encoding : utf-8 -*-
Olook::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true
  config.assets.css_compressor = :yui
  config.assets.js_compressor = :uglifier

  # Fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  config.log_level = :info

  # Use a different logger for distributed setups
  #config.logger = SyslogLogger.new('rails-olook-prod')

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store
  config.cache_store = :redis_store, ENV['REDIS_CACHE_STORE'], { expires_in: 40.minutes }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  config.action_controller.asset_host = Proc.new { |source, request| 
    if request.ssl?
      "https://gp1.wac.edgecastcdn.net/80BFF9/assets"
    else
      "http://wac.bff9.edgecastcdn.net/80BFF9/assets"
    end
  }

  # config.action_controller.asset_host = Proc.new do |source, request|
  #   request.ssl? ? "https://cdn-app.olook.com.br.s3.amazonaws.com" : "http://cdn-app.olook.com.br.s3.amazonaws.com"
  # end

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # config.assets.paths << "#{Rails.root}/public/assets/admin #{Rails.root}/public/assets/common #{Rails.root}/public/assets/gift #{Rails.root}/public/assets/plugins #{Rails.root}/public/assets/ui #{Rails.root}/public/assets/section"
  config.assets.precompile += %w(*.js admin.css campaign_emails.css admin/*.css admin/*.js about/*.css common/*.css common/*.js gift/*.js plugins/*.js ui/*.js section/*.css utilities/*.css customlanding.css)

  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = true

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

end
