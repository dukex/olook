module MonkeyPatches
  extend self

  NET_HTTP_SINGLETON = class << Net::HTTP; self; end

  MONKEY_PATCHES = [
    [Net::BufferedIO,    :initialize],
    [Net::HTTP,          :request],
    [Net::HTTP,          :connect],
    [NET_HTTP_SINGLETON, :socket_type]
  ]

  def enable!(scope)
    case scope
      when :fakeweb
        realias_all :with_fakeweb
        enable!(:vcr) # fakeweb adapter relies upon VCR's Net::HTTP monkey patch
      when :webmock
        ::WebMock::HttpLibAdapters::NetHttpAdapter.enable!
        ::WebMock::HttpLibAdapters::TyphoeusAdapter.enable! unless RUBY_INTERPRETER == :jruby
        $original_webmock_callbacks.each do |cb|
          ::WebMock::CallbackRegistry.add_callback(cb[:options], cb[:block])
        end
      when :vcr
        realias Net::HTTP, :request, :with_vcr
      else raise ArgumentError.new("Unexpected scope: #{scope}")
    end
  end

  def disable_all!
    realias_all :without_monkeypatches

    if defined?(::WebMock)
      ::WebMock::HttpLibAdapters::NetHttpAdapter.disable!
      ::WebMock::HttpLibAdapters::TyphoeusAdapter.disable! unless RUBY_INTERPRETER == :jruby
      ::WebMock::CallbackRegistry.reset
    end
  end

  def init
    # capture the monkey patched definitions so we can realias to them in the future
    MONKEY_PATCHES.each do |mp|
      capture_method_definition(mp.first, mp.last, false)
    end
  end

  private

  def capture_method_definition(klass, method, original)
    klass.class_eval do
      monkeypatch_methods = [:vcr, :fakeweb].select { |m| method_defined?(:"#{method}_with_#{m}") }

      if original
        if monkeypatch_methods.size > 0
          raise "The following monkeypatch methods have already been defined #{method}: #{monkey_patch_methods.inspect}"
        end
        alias_name = :"#{method}_without_monkeypatches"
      else
        if monkeypatch_methods.size == 0
          raise "No monkey patch methods have been defined for #{method}"
        end
        alias_name = :"#{method}_with_monkeypatches"
      end

      alias_method alias_name, method
    end
  end

  # capture the original method definitions before the monkey patches have been defined
  # so we can realias to the originals in the future
  MONKEY_PATCHES.each do |mp|
    capture_method_definition(mp.first, mp.last, true)
  end

  def realias(klass, method, alias_extension)
    klass.class_eval do
      old_verbose, $VERBOSE = $VERBOSE, nil
      alias_method method, :"#{method}_#{alias_extension}"
      $VERBOSE = old_verbose
    end
  end

  def realias_all(alias_extension)
    MONKEY_PATCHES.each do |mp|
      realias mp.first, mp.last, alias_extension
    end
  end
end

# Require all the HTTP libraries--these must be required before WebMock
# for WebMock to work with them.
require 'httpclient'

if RUBY_INTERPRETER == :mri
  require 'patron'
  require 'em-http-request'
  require 'curb'
  require 'typhoeus'
end

require 'vcr/http_stubbing_adapters/fakeweb'

# All Net::HTTP monkey patches have now been loaded, so capture the
# appropriate method definitions so we can disable them later.
MonkeyPatches.init

# Disable FakeWeb/VCR Net::HTTP patches before WebMock
# subclasses Net::HTTP and inherits them...
MonkeyPatches.disable_all!

require 'vcr/http_stubbing_adapters/webmock'
$original_webmock_callbacks = ::WebMock::CallbackRegistry.callbacks

# disable all by default; we'll enable specific ones when we need them
MonkeyPatches.disable_all!

RSpec.configure do |config|
  [:fakeweb, :webmock, :vcr].each do |scope|
    config.before(:all, :with_monkey_patches => scope) { MonkeyPatches.enable!(scope) }
    config.after(:all,  :with_monkey_patches => scope) { MonkeyPatches.disable_all!   }
  end
end

