require 'fog/vcloud/models/compute/vdcs'

Shindo.tests("Vcloud::Compute | vdcs", ['vcloud']) do

  pending if Fog.mocking?

   instance = Fog::Vcloud::Compute::Vdcs.new(
    :connection => Fog::Vcloud::Compute.new(:vcloud_host => 'vcloud.example.com', :vcloud_username => 'username', :vcloud_password => 'password'),
    :href       =>  "https://vcloud.example.com/api/v1.0/org/1"
   )

  tests("collection") do
    returns(1) { instance.size }
    returns("https://vcloud.example.com/api/v1.0/vdc/1") { instance.first.href }
  end

end
