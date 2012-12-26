module Fog
  module Rackspace
    class LoadBalancers
      class Real
        def get_load_balancer(load_balancer_id)
          request(
            :expects => 200,
            :path => "loadbalancers/#{load_balancer_id}.json",
            :method => 'GET'
          )
         end
      end
    end
  end
end
