# -*- encoding : utf-8 -*-
require 'rubygems'
require 'spork'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  require 'simplecov'
  SimpleCov.start 'rails' do
    add_group "Long files" do |src_file|
      src_file.lines.count > 100
    end
    add_filter "/vendor/"
  end

  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'

  # Since we're using devise, the spork guys recommend us to reload the routes on this step
  # https://github.com/timcharper/spork/wiki/Spork.trap_method-Jujutsu
  Spork.trap_method(Rails::Application::RoutesReloader, :reload!) if defined?(Rails)

  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'capybara/rspec'
  require 'carrierwave/test/matchers'

  OmniAuth.config.test_mode = true

  OmniAuth.config.mock_auth[:facebook] = {
    'provider' => 'facebook',
    'extra' => {"raw_info" => {"email" => "user@mail.com", "first_name" => "User Name", "last_name" => "Last Name", "id" => "abc"}},
    'credentials' => {'token' => "AXDV"}
  }

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  #Requires libs. Check why I need to do it later
  Dir[Rails.root.join("lib/**/*.rb")].each {|f| require f}

  Savon.configure do |config|

    # By default, Savon logs each SOAP request and response to $stdout.
    # Here's how you can disable logging:
    config.log = false
    
  end

  HTTPI.log = false

  RSpec.configure do |config|
    # == Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    config.before(:suite) do
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.clean_with(:truncation)
    end

    config.mock_with :rspec

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{::Rails.root}/spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    config.include Devise::TestHelpers, :type => :controller
    config.extend VCR::RSpec::Macros
    config.include Abacos::TestHelpers
  end
end

Spork.each_run do
  FactoryGirl.reload
  Dir[File.expand_path("app/controllers/user/*.rb")].each do |file|
    require file
  end
end
