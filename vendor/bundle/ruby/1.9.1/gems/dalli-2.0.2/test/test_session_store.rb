require 'helper'
require 'abstract_unit'
require 'action_dispatch/middleware/session/dalli_store'

class Foo
  def initialize(bar='baz')
    @bar = bar
  end
  def inspect
    "#<#{self.class} bar:#{@bar.inspect}>"
  end
end

class TestSessionStore < ActionController::IntegrationTest
  class TestController < ActionController::Base
    def no_session_access
      head :ok
    end

    def set_session_value
      session[:foo] = "bar"
      head :ok
    end

    def set_serialized_session_value
      session[:foo] = Foo.new
      head :ok
    end

    def get_session_value
      render :text => "foo: #{session[:foo].inspect}"
    end

    def get_session_id
      render :text => "#{request.session_options[:id]}"
    end

    def call_reset_session
      session[:bar]
      reset_session
      session[:bar] = "baz"
      head :ok
    end

    def rescue_action(e) raise end
  end

  begin
    require 'dalli'
    memcache = Dalli::Client.new('127.0.0.1:11211')
    memcache.set('ping', '')

    def test_setting_and_getting_session_value
      with_test_route_set do
        get '/set_session_value'
        assert_response :success
        assert cookies['_session_id']

        get '/get_session_value'
        assert_response :success
        assert_equal 'foo: "bar"', response.body
      end
    end

    def test_getting_nil_session_value
      with_test_route_set do
        get '/get_session_value'
        assert_response :success
        assert_equal 'foo: nil', response.body
      end
    end

    def test_getting_session_value_after_session_reset
      with_test_route_set do
        get '/set_session_value'
        assert_response :success
        assert cookies['_session_id']
        session_cookie = cookies.send(:hash_for)['_session_id']

        get '/call_reset_session'
        assert_response :success
        assert_not_equal [], headers['Set-Cookie']

        cookies << session_cookie # replace our new session_id with our old, pre-reset session_id

        get '/get_session_value'
        assert_response :success
        assert_equal 'foo: nil', response.body, "data for this session should have been obliterated from memcached"
      end
    end

    def test_getting_from_nonexistent_session
      with_test_route_set do
        get '/get_session_value'
        assert_response :success
        assert_equal 'foo: nil', response.body
        assert_nil cookies['_session_id'], "should only create session on write, not read"
      end
    end

    def test_setting_session_value_after_session_reset
      with_test_route_set do
        get '/set_session_value'
        assert_response :success
        assert cookies['_session_id']
        session_id = cookies['_session_id']

        get '/call_reset_session'
        assert_response :success
        assert_not_equal [], headers['Set-Cookie']

        get '/get_session_value'
        assert_response :success
        assert_equal 'foo: nil', response.body

        get '/get_session_id'
        assert_response :success
        assert_not_equal session_id, response.body
      end
    end

    def test_getting_session_id
      with_test_route_set do
        get '/set_session_value'
        assert_response :success
        assert cookies['_session_id']
        session_id = cookies['_session_id']

        get '/get_session_id'
        assert_response :success
        assert_equal session_id, response.body, "should be able to read session id without accessing the session hash"
      end
    end

    def test_deserializes_unloaded_class
      with_test_route_set do
        with_autoload_path "session_autoload_test" do
          get '/set_serialized_session_value'
          assert_response :success
          assert cookies['_session_id']
        end
        with_autoload_path "session_autoload_test" do
          get '/get_session_id'
          assert_response :success
        end
        with_autoload_path "session_autoload_test" do
          get '/get_session_value'
          assert_response :success
          assert_equal 'foo: #<Foo bar:"baz">', response.body, "should auto-load unloaded class"
        end
      end
    end

    def test_doesnt_write_session_cookie_if_session_id_is_already_exists
      with_test_route_set do
        get '/set_session_value'
        assert_response :success
        assert cookies['_session_id']

        get '/get_session_value'
        assert_response :success
        assert_equal nil, headers['Set-Cookie'], "should not resend the cookie again if session_id cookie is already exists"
      end
    end

    def test_prevents_session_fixation
      with_test_route_set do
        get '/get_session_value'
        assert_response :success
        assert_equal 'foo: nil', response.body
        session_id = cookies['_session_id']

        reset!

        get '/set_session_value', :_session_id => session_id
        assert_response :success
        assert_not_equal session_id, cookies['_session_id']
      end
    end

    def test_expire_after
      with_test_route_set(:expire_after => 1) do
        get '/set_session_value'
        assert_match /expires/, @response.headers['Set-Cookie']

        sleep(1)

        get '/get_session_value'
        assert_equal 'foo: nil', response.body
      end
    end

    def test_expires_in
      with_test_route_set(:expires_in => 1) do
        get '/set_session_value'
        assert_no_match /expires/, @response.headers['Set-Cookie']

        sleep(1)

        get '/get_session_value'
        assert_equal 'foo: nil', response.body
      end
    end
  rescue LoadError, RuntimeError
    $stderr.puts "Skipping SessionStore tests. Start memcached and try again: #{$!.message}"
  end

  private

  def with_test_route_set(options = {})
    options = {:key => '_session_id', :memcache_server => '127.0.0.1:11211'}.merge(options)
    with_routing do |set|
      set.draw do
        match ':action', :to => ::TestSessionStore::TestController
      end

      @app = self.class.build_app(set) do |middleware|
        middleware.use ActionDispatch::Session::DalliStore, options
      end

      yield
    end
  end
end
