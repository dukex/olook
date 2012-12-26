Feature: Usage with Cucumber

  VCR can be used with cucumber in two basic ways:

    - Use `VCR.use_cassette` in a step definition.
    - Use a `VCR.cucumber_tags` block to tell VCR to use a
      cassette for a tagged scenario.

  In a cucumber support file (e.g. features/support/vcr.rb), put code like this:

      VCR.cucumber_tags do |t|
        t.tag  '@tag1'
        t.tags '@tag2', '@tag3'

        t.tag  '@tag3', :cassette => :options
        t.tags '@tag4, '@tag5', :cassette => :options
      end

  VCR will use a cassette named "cucumber_tags/<tag_name>" for scenarios
  with each of these tags.  The configured `default_cassette_options` will
  be used, or you can override specific options by passing a hash as the
  last argument to `#tag` or `#tags`.

  Scenario: Record HTTP interactions in a scenario by tagging it
    Given a file named "lib/server.rb" with:
      """
      require 'vcr_cucumber_helpers'

      if ENV['WITH_SERVER'] == 'true'
        start_sinatra_app(:port => 7777) do
          get('/:path') { "Hello #{params[:path]}" }
        end
      end
      """

    Given a file named "features/support/vcr.rb" with:
      """
      require "lib/server"
      require 'vcr'

      VCR.config do |c|
        c.stub_with :webmock
        c.cassette_library_dir     = 'features/cassettes'
        c.default_cassette_options = { :record => :new_episodes }
      end

      VCR.cucumber_tags do |t|
        t.tag  '@localhost_request' # uses default record mode since no options are given
        t.tags '@disallowed_1', '@disallowed_2', :record => :none
      end
      """
    And a file named "features/step_definitions/steps.rb" with:
      """
      require 'net/http'

      When /^a request is made to "([^"]*)"$/ do |url|
        @response = Net::HTTP.get_response(URI.parse(url))
      end

      When /^(.*) within a cassette named "([^"]*)"$/ do |step, cassette_name|
        VCR.use_cassette(cassette_name) { When step }
      end

      Then /^the response should be "([^"]*)"$/ do |expected_response|
        @response.body.should == expected_response
      end
      """
    And a file named "features/vcr_example.feature" with:
      """
      Feature: VCR example

        @localhost_request
        Scenario: tagged scenario
          When a request is made to "http://localhost:7777/localhost_request_1"
          Then the response should be "Hello localhost_request_1"
          When a request is made to "http://localhost:7777/nested_cassette" within a cassette named "nested_cassette"
          Then the response should be "Hello nested_cassette"
          When a request is made to "http://localhost:7777/localhost_request_2"
          Then the response should be "Hello localhost_request_2"

        @disallowed_1
        Scenario: tagged scenario
          When a request is made to "http://localhost:7777/allowed" within a cassette named "allowed"
          Then the response should be "Hello allowed"
          When a request is made to "http://localhost:7777/disallowed_1"

        @disallowed_2
        Scenario: tagged scenario
          When a request is made to "http://localhost:7777/disallowed_2"
      """
    And the directory "features/cassettes" does not exist
    When I run `cucumber WITH_SERVER=true features/vcr_example.feature`
    Then it should fail with "3 scenarios (2 failed, 1 passed)"
    And the output should contain each of the following:
      | Real HTTP connections are disabled. Unregistered request: GET http://localhost:7777/disallowed_1 |
      | Real HTTP connections are disabled. Unregistered request: GET http://localhost:7777/disallowed_2 |
    And the file "features/cassettes/cucumber_tags/localhost_request.yml" should contain "body: Hello localhost_request_1"
    And the file "features/cassettes/cucumber_tags/localhost_request.yml" should contain "body: Hello localhost_request_2"
    And the file "features/cassettes/nested_cassette.yml" should contain "body: Hello nested_cassette"
    And the file "features/cassettes/allowed.yml" should contain "body: Hello allowed"

    # Run again without the server; we'll get the same responses because VCR
    # will replay the recorded responses.
    When I run `cucumber features/vcr_example.feature`
    Then it should fail with "3 scenarios (2 failed, 1 passed)"
    And the output should contain each of the following:
      | Real HTTP connections are disabled. Unregistered request: GET http://localhost:7777/disallowed_1 |
      | Real HTTP connections are disabled. Unregistered request: GET http://localhost:7777/disallowed_2 |
    And the file "features/cassettes/cucumber_tags/localhost_request.yml" should contain "body: Hello localhost_request_1"
    And the file "features/cassettes/cucumber_tags/localhost_request.yml" should contain "body: Hello localhost_request_2"
    And the file "features/cassettes/nested_cassette.yml" should contain "body: Hello nested_cassette"
    And the file "features/cassettes/allowed.yml" should contain "body: Hello allowed"

