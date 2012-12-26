Feature: :all

  The `:all` record mode will:

    - Record new interactions.
    - Never replay previously recorded interactions.

  This can be temporarily used to force VCR to re-record
  a cassette (i.e. to ensure the responses are not out of date)
  or can be used when you simply want to log all HTTP requests.

  Background:
    Given a file named "setup.rb" with:
      """
      require 'vcr_cucumber_helpers'

      start_sinatra_app(:port => 7777) do
        get('/')    { 'Hello' }
        get('/foo') { 'Goodbye' }
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
          uri: http://localhost:7777/
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
          body: old response
          http_version: "1.1"
      """

  Scenario: Re-record previously recorded response
    Given a file named "re_record.rb" with:
      """
      require 'setup'

      VCR.use_cassette('example', :record => :all) do
        response = Net::HTTP.get_response('localhost', '/', 7777)
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby re_record.rb`
    Then it should pass with "Response: Hello"
    And the file "cassettes/example.yml" should contain "body: Hello"
    But the file "cassettes/example.yml" should not contain "body: old response"

  Scenario: Record new request
    Given a file named "record_new.rb" with:
      """
      require 'setup'

      VCR.use_cassette('example', :record => :all) do
        response = Net::HTTP.get_response('localhost', '/foo', 7777)
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby record_new.rb`
    Then it should pass with "Response: Goodbye"
    And the file "cassettes/example.yml" should contain each of these:
      | body: old response |
      | body: Goodbye      |
