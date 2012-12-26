require 'fog/core/model'

module Fog
  module AWS
    class Elasticache

      class ParameterGroup < Fog::Model

        identity :id, :aliases => 'CacheParameterGroupName'
        attribute :description, :aliases => 'Description'
        attribute :family, :aliases => 'CacheParameterGroupFamily'

        def destroy
          requires :id
          connection.delete_cache_parameter_group(id)
          true
        end

        def save
          requires :id
          connection.create_cache_parameter_group(
            id,
            description = id,
            family      = 'memcached1.4'
          )
        end

      end

    end
  end
end
