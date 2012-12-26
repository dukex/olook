module Fog
  module Storage
    class Google
      class Real

        require 'fog/google/parsers/storage/get_service'

        # List information about Google Storage buckets for authorized user
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Buckets'<~Hash>:
        #       * 'Name'<~String> - Name of bucket
        #       * 'CreationTime'<~Time> - Timestamp of bucket creation
        #     * 'Owner'<~Hash>:
        #       * 'DisplayName'<~String> - Display name of bucket owner
        #       * 'ID'<~String> - Id of bucket owner
        def get_service
          request({
            :expects  => 200,
            :headers  => {},
            :host     => @host,
            :idempotent => true,
            :method   => 'GET',
            :parser   => Fog::Parsers::Storage::Google::GetService.new,
            :url      => @host
          })
        end

      end

      class Mock

        def get_service
          response = Excon::Response.new
          response.headers['Status'] = 200
          buckets = self.data[:buckets].values.map do |bucket|
            bucket.reject do |key, value|
              !['CreationDate', 'Name'].include?(key)
            end
          end
          response.body = {
            'Buckets' => buckets,
            'Owner'   => { 'ID' => 'some_id'}
          }
          response
        end

      end
    end
  end
end
