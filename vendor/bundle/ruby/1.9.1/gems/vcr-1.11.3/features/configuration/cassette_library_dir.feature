Feature: cassette_library_dir

  The `cassette_library_dir` configuration option sets a directory
  where VCR saves each cassette.

  Scenario: cassette_library_dir
    Given a file named "cassette_library_dir.rb" with:
      """
      require 'vcr_cucumber_helpers'

      start_sinatra_app(:port => 7777) do
        get('/') { "Hello" }
      end

      require 'vcr'

      VCR.config do |c|
        c.cassette_library_dir = 'vcr/cassettes'
        c.stub_with :fakeweb
      end

      VCR.use_cassette('localhost', :record => :new_episodes) do
        Net::HTTP.get_response('localhost', '/', 7777)
      end
      """
     And the directory "vcr/cassettes" does not exist
    When I run `ruby cassette_library_dir.rb`
    Then the file "vcr/cassettes/localhost.yml" should exist
