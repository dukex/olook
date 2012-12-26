Feature: :once

  The `:once` record mode will:

    - Replay previously recorded interactions.
    - Record new interactions if there is no cassette file.
    - Cause an error to be raised for new requests if there is a cassette file.

  It is similar to the `:new_episodes` record mode, but will prevent new,
  unexpected requests from being made (i.e. because the request URI changed
  or whatever).

  `:once` is the default record mode, used when you do not set one.

  Background:
    Given a file named "setup.rb" with:
      """
      require 'vcr_cucumber_helpers'

      start_sinatra_app(:port => 7777) do
        get('/') { 'Hello' }
      end

      require 'vcr'

      VCR.config do |c|
        c.stub_with                :fakeweb
        c.cassette_library_dir     = 'cassettes'
      end
      """
    And a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://example.com:80/foo
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-type: 
            - text/html;charset=utf-8
            content-length: 
            - "20"
          body: example.com response
          http_version: "1.1"
      """

  Scenario: Previously recorded responses are replayed
    Given a file named "replay_recorded_response.rb" with:
      """
      require 'setup'

      VCR.use_cassette('example', :record => :once) do
        response = Net::HTTP.get_response('example.com', '/foo')
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby replay_recorded_response.rb`
    Then it should pass with "Response: example.com response"

  Scenario: New requests result in an error when the cassette file exists
    Given a file named "error_for_new_requests_when_cassette_exists.rb" with:
      """
      require 'setup'

      VCR.use_cassette('example', :record => :once) do
        response = Net::HTTP.get_response('localhost', '/', 7777)
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby error_for_new_requests_when_cassette_exists.rb`
    Then it should fail with "Real HTTP connections are disabled"

  Scenario: New requests get recorded when there is no cassette file
    Given a file named "record_new_requests.rb" with:
      """
      require 'setup'

      VCR.use_cassette('example', :record => :once) do
        response = Net::HTTP.get_response('localhost', '/', 7777)
        puts "Response: #{response.body}"
      end
      """
    When I remove the file "cassettes/example.yml"
    And I run `ruby record_new_requests.rb`
    Then it should pass with "Response: Hello"
    And the file "cassettes/example.yml" should contain "body: Hello"
