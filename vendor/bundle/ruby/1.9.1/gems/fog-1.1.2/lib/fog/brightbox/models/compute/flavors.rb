require 'fog/core/collection'
require 'fog/brightbox/models/compute/flavor'

module Fog
  module Compute
    class Brightbox

      class Flavors < Fog::Collection

        model Fog::Compute::Brightbox::Flavor

        def all
          data = connection.list_server_types
          load(data)
        end

        def get(identifier)
          data = connection.get_server_type(identifier)
          new(data)
        rescue Excon::Errors::NotFound
          nil
        end

      end

    end
  end
end