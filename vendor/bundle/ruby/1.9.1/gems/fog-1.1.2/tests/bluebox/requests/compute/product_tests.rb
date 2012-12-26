Shindo.tests('Fog::Compute[:bluebox] | product requests', ['bluebox']) do

  tests('success') do

    @product_id   = '94fd37a7-2606-47f7-84d5-9000deda52ae' # 1 GB

    tests("get_product('#{@product_id}')").formats(Bluebox::Compute::Formats::PRODUCT) do
      pending if Fog.mocking?
      Fog::Compute[:bluebox].get_product(@product_id).body
    end

    tests("get_products").formats([Bluebox::Compute::Formats::PRODUCT]) do
      pending if Fog.mocking?
      Fog::Compute[:bluebox].get_products.body
    end

  end

  tests('failure') do

    tests("get_product('00000000-0000-0000-0000-000000000000')").raises(Fog::Compute::Bluebox::NotFound) do
      pending if Fog.mocking?
      Fog::Compute[:bluebox].get_product('00000000-0000-0000-0000-000000000000')
    end

  end

end
