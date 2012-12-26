module Fog
  module Compute
    class Brightbox
      class Real

        def list_servers
          request("get", "/1.0/servers", [200])
        end

      end
    end
  end
end