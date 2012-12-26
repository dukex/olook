require 'fog/vcloud/models/compute/vdc'

module Fog
  module Vcloud
    class Compute

      class Vdcs < Collection

        model Fog::Vcloud::Compute::Vdc

        undef_method :create

        attribute :href

        def all
          links = (l=connection.get_organization(org_uri).body[:Link]).is_a?(Array) ? l : [l].compact
          data = links.select { |link| link[:type] == "application/vnd.vmware.vcloud.vdc+xml" }
          data.each { |link| link.delete_if { |key, value| [:rel].include?(key) } }
          load(data)
        end

        def get(uri)
          if data = connection.get_vdc(uri)
            new(data.body)
          end
        rescue Fog::Errors::NotFound
          nil
        end

        private

        def org_uri
          self.href ||= connection.default_organization_uri
        end
      end
    end
  end
end
