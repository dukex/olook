# -*- encoding : utf-8 -*-
Olook::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  config.serve_static_assets = true
  config.log_level = :debug
  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  # Don't send real emails in development env
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = !!ENV['DEBUG_ASSETS']
  config.assets.prefix = "/dev-assets"
  config.action_mailer.asset_host = "http://localhost:3000"

  config.cache_store = :redis_store, ENV['REDIS_CACHE_STORE'], { expires_in: 5.minutes }

  # If you are running on a Ubuntu in development mode, you'll need this for connecting on ssl sites
  Excon.defaults[:ssl_ca_path] = '/etc/ssl/certs' if `uname -v`.upcase.index 'UBUNTU'
end
