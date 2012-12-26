@exclude-jruby @exclude-rbx @exclude-travis-186
Feature: EM HTTP Request

  EM HTTP Request allows multiple simultaneous asynchronous requests.
  (The other HTTP libraries are synchronous).  The scenarios below
  demonstrate how VCR can be used with asynchronous em-http requests.

  Background:
    Given a file named "vcr_setup.rb" with:
      """
      require 'em-http-request'
      require 'vcr_cucumber_helpers'

      start_sinatra_app(:port => 7777) do
        %w[ foo bar bazz ].each_with_index do |path, index|
          get "/#{path}" do
            sleep index * 0.1 # ensure the async callbacks are invoked in order
            ARGV[0] + ' ' + path
          end
        end
      end

      require 'vcr'

      VCR.config do |c|
        c.stub_with :webmock
        c.cassette_library_dir = 'cassettes'
      end
      """

  Scenario: multiple simultaneous HttpRequest objects
    Given a file named "make_requests.rb" with:
      """
      require 'vcr_setup'

      VCR.use_cassette('em_http', :record => :new_episodes) do
        EventMachine.run do
          http_array = %w[ foo bar bazz ].map do |p|
            EventMachine::HttpRequest.new("http://localhost:7777/#{p}").get
          end

          http_array.each do |http|
            http.callback do
              puts http.response

              if http_array.all? { |h| h.response.to_s != '' }
                EventMachine.stop
              end
            end
          end
        end
      end
      """
    When I run `ruby make_requests.rb Hello`
    Then the output should contain:
      """
      Hello foo
      Hello bar
      Hello bazz
      """
    And the file "cassettes/em_http.yml" should contain YAML like:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://localhost:7777/foo
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
            - "9"
          body: Hello foo
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://localhost:7777/bar
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
            - "9"
          body: Hello bar
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://localhost:7777/bazz
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
            - "10"
          body: Hello bazz
          http_version: "1.1"
      """

    When I run `ruby make_requests.rb Goodbye`
    Then the output should contain:
      """
      Hello foo
      Hello bar
      Hello bazz
      """

  Scenario: MultiRequest
    Given a file named "make_requests.rb" with:
      """
      require 'vcr_setup'

      VCR.use_cassette('em_http', :record => :new_episodes) do
        EventMachine.run do
          multi = EventMachine::MultiRequest.new

          %w[ foo bar bazz ].each do |path|
            multi.add(EventMachine::HttpRequest.new("http://localhost:7777/#{path}").get)
          end

          multi.callback do
            multi.responses[:succeeded].each do |http|
              puts http.response
            end
            EventMachine.stop
          end
        end
      end
      """
    When I run `ruby make_requests.rb Hello`
    Then the output should contain:
      """
      Hello foo
      Hello bar
      Hello bazz
      """
    And the file "cassettes/em_http.yml" should contain YAML like:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://localhost:7777/foo
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
            - "9"
          body: Hello foo
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://localhost:7777/bar
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
            - "9"
          body: Hello bar
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://localhost:7777/bazz
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
            - "10"
          body: Hello bazz
          http_version: "1.1"
      """

    When I run `ruby make_requests.rb Goodbye`
    Then the output should contain:
      """
      Hello foo
      Hello bar
      Hello bazz
      """

