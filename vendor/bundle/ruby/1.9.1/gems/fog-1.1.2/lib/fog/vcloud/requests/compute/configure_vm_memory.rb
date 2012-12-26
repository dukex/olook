# -*- coding: utf-8 -*-
module Fog
  module Vcloud
    class Compute
      class Real

        def configure_vm_memory(vm_data)
          edit_uri = vm_data.select {|k,v| k == :Link && v[:rel] == 'edit'}
          edit_uri = edit_uri.kind_of?(Array) ? edit_uri.flatten[1][:href] : edit_uri[:Link][:href]

          body = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Item xmlns="http://www.vmware.com/vcloud/v1" xmlns:rasd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData" xmlns:vcloud="http://www.vmware.com/vcloud/v1" vcloud:href="https://vcd01.esx.dev.int.realestate.com.au/api/v1.0/vApp/vm-329805878/virtualHardwareSection/memory" vcloud:type="application/vnd.vmware.vcloud.rasdItem+xml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2.22.0/CIM_ResourceAllocationSettingData.xsd http://www.vmware.com/vcloud/v1 http://vcd01.esx.dev.int.realestate.com.au/api/v1.0/schema/master.xsd">
    <rasd:AllocationUnits>byte * 2^20</rasd:AllocationUnits>
    <rasd:Description>Memory Size</rasd:Description>
    <rasd:ElementName>#{vm_data[:'rasd:VirtualQuantity']} MB of memory</rasd:ElementName>
    <rasd:InstanceID>5</rasd:InstanceID>
    <rasd:Reservation>0</rasd:Reservation>
    <rasd:ResourceType>4</rasd:ResourceType>
    <rasd:VirtualQuantity>#{vm_data[:'rasd:VirtualQuantity']}</rasd:VirtualQuantity>
    <rasd:Weight>5120</rasd:Weight>
    <Link rel="edit" type="application/vnd.vmware.vcloud.rasdItem+xml" href="https://vcd01.esx.dev.int.realestate.com.au/api/v1.0/vApp/vm-329805878/virtualHardwareSection/memory"/>
</Item>
EOF

          request(
            :body     => body,
            :expects  => 202,
            :headers  => {'Content-Type' => vm_data[:"vcloud_type"] },
            :method   => 'PUT',
            :uri      => edit_uri,
            :parse    => true
          )
        end

      end

    end
  end
end
