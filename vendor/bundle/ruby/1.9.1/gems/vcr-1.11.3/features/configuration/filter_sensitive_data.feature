Feature: Filter sensitive data

  The `filter_sensitive_data` configuration option can be used to prevent
  sensitive data from being written to your cassette files.  This may be
  important if you commit your cassettes files to source control and do
  not want your sensitive data exposed.  Pass the following arguments to
  `filter_sensitive_data`:

    - A substitution string.  This is the string that will be written to
      the cassettte file as a placeholder.  It should be unique and you
      may want to wrap it in special characters like `{ }` or `< >`.
    - A symbol specifying a tag (optional).  If a tag is given, the
      filtering will only be applied to cassettes with the given tag.
    - A block.  The block should return the sensitive text that you want
      replaced with the substitution string.  If your block accepts an
      argument, the HTTP interaction will be yielded so that you can
      dynamically specify the sensitive text based on the interaction
      (see the last scenario for an example of this).

  When the interactions are replayed, the sensitive text will replace the
  substitution string so that the interaction will be identical to what was
  originally recorded.

  You can specify as many filterings as you want.

  Scenario: Multiple filterings
    Given a file named "filtering.rb" with:
      """
      require 'vcr_cucumber_helpers'

      if ARGV.include?('--with-server')
        start_sinatra_app(:port => 7777) do
          get('/') { "Hello World" }
        end
      end

      require 'vcr'

      VCR.config do |c|
        c.stub_with :fakeweb
        c.cassette_library_dir = 'cassettes'
        c.filter_sensitive_data('<GREETING>') { 'Hello' }
        c.filter_sensitive_data('<LOCATION>') { 'World' }
      end

      VCR.use_cassette('filtering', :record => :new_episodes) do
        response = Net::HTTP.get_response('localhost', '/', 7777)
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby filtering.rb --with-server`
    Then the output should contain "Response: Hello World"
     And the file "cassettes/filtering.yml" should contain "body: <GREETING> <LOCATION>"
     And the file "cassettes/filtering.yml" should not contain "Hello"
     And the file "cassettes/filtering.yml" should not contain "World"

    When I run `ruby filtering.rb`
    Then the output should contain "Hello World"

  Scenario: Filter tagged cassettes
    Given a file named "tagged_filtering.rb" with:
      """
      require 'vcr_cucumber_helpers'

      if ARGV.include?('--with-server')
        response_count = 0
        start_sinatra_app(:port => 7777) do
          get('/') { "Hello World #{response_count += 1 }" }
        end
      end

      require 'vcr'

      VCR.config do |c|
        c.stub_with :fakeweb
        c.cassette_library_dir = 'cassettes'
        c.filter_sensitive_data('<LOCATION>', :my_tag) { 'World' }
      end

      VCR.use_cassette('tagged', :tag => :my_tag, :record => :new_episodes) do
        response = Net::HTTP.get_response('localhost', '/', 7777)
        puts "Tagged Response: #{response.body}"
      end

      VCR.use_cassette('untagged', :record => :new_episodes) do
        response = Net::HTTP.get_response('localhost', '/', 7777)
        puts "Untagged Response: #{response.body}"
      end
      """
    When I run `ruby tagged_filtering.rb --with-server`
    Then the output should contain each of the following:
      | Tagged Response: Hello World 1   |
      | Untagged Response: Hello World 2 |
     And the file "cassettes/tagged.yml" should contain "body: Hello <LOCATION> 1"
     And the file "cassettes/untagged.yml" should contain "body: Hello World 2"

    When I run `ruby tagged_filtering.rb`
    Then the output should contain each of the following:
      | Tagged Response: Hello World 1   |
      | Untagged Response: Hello World 2 |

  Scenario: Filter dynamic data based on yielded HTTP interaction
    Given a file named "dynamic_filtering.rb" with:
      """
      require 'vcr_cucumber_helpers'
      include_http_adapter_for('net/http')

      if ARGV.include?('--with-server')
        start_sinatra_app(:port => 7777) do
          helpers do
            def request_header_for(header_key_fragment)
              key = env.keys.find { |k| k =~ /#{header_key_fragment}/i }
              env[key]
            end
          end

          get('/') { "#{request_header_for('username')}/#{request_header_for('password')}" }
        end
      end

      require 'vcr'

      USER_PASSWORDS = {
        'john.doe' => 'monkey',
        'jane.doe' => 'cheetah'
      }

      VCR.config do |c|
        c.stub_with :webmock
        c.cassette_library_dir = 'cassettes'
        c.filter_sensitive_data('<PASSWORD>') do |interaction|
          USER_PASSWORDS[interaction.request.headers['x-http-username'].first]
        end
      end

      VCR.use_cassette('example', :record => :new_episodes, :match_requests_on => [:method, :uri, :headers]) do
        puts "Response: " + response_body_for(
          :get, 'http://localhost:7777/', nil,
          'X-HTTP-USERNAME' => 'john.doe',
          'X-HTTP-PASSWORD' => USER_PASSWORDS['john.doe']
        )
      end
      """
    When I run `ruby dynamic_filtering.rb --with-server`
    Then the output should contain "john.doe/monkey"
    And the file "cassettes/example.yml" should contain "body: john.doe/<PASSWORD>"
    And the file "cassettes/example.yml" should contain a YAML fragment like:
      """
      x-http-password:
      - <PASSWORD>
      """

    When I run `ruby dynamic_filtering.rb`
    Then the output should contain "john.doe/monkey"
