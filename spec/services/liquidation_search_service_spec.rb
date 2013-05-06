require "spec_helper"

describe LiquidationSearchService do
  let(:basic_shoe_size_35) { FactoryGirl.create(:basic_shoe_size_35) }
  let(:basic_shoe_size_37) { FactoryGirl.create(:basic_shoe_size_37) }
  let(:basic_shoe_size_40) { FactoryGirl.create(:basic_shoe_size_40) }

  let(:basic_bag) { FactoryGirl.create(:basic_bag) }
  let(:basic_accessory) { FactoryGirl.create(:basic_accessory) }

  let(:basic_bag_1) { FactoryGirl.create(:basic_bag_simple, :product => basic_bag) }
  let(:basic_accessory_1) { FactoryGirl.create(:basic_accessory_simple, :product => basic_accessory) }

  let(:liquidation) { FactoryGirl.create(:liquidation) }

  before :each do
    Liquidation.delete_all
    LiquidationProduct.delete_all
    Product.delete_all
    Variant.delete_all
  end

  describe "#search_products" do
    context "isolated filters" do
       it "returns products given some subcategories" do
         lp1 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, variant_id: basic_shoe_size_35.id, :subcategory_name => "rasteirinha", :inventory => 1)
         lp2 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, variant_id: basic_shoe_size_40.id, :subcategory_name => "melissa", :inventory => 1)
         lp3 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, variant_id: basic_shoe_size_37.id, :heel => 5.6, :inventory => 1)
         params = {:id => liquidation.id, :shoe_subcategories => ["rasteirinha", "melissa"]}
         products = LiquidationSearchService.new(params).search_products
         products.should include(lp1)
         products.should include(lp2)
         products.should_not include(lp3)
       end

       it "returns products given some shoe sizes and subcategories" do
         lp1 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, variant_id: basic_shoe_size_35.id, :subcategory_name => "rasteirinha", :shoe_size => 45, :inventory => 1)
         lp2 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, variant_id: basic_shoe_size_40.id, :subcategory_name => "melissa", :shoe_size => 35, :inventory => 1)
         lp3 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, variant_id: basic_shoe_size_37.id, :heel => 5.6, :inventory => 1)
         params = {:id => liquidation.id, :shoe_subcategories => ["rasteirinha", "melissa"], :shoe_sizes => ["45", "35"]}
         products = LiquidationSearchService.new(params).search_products
         products.should include(lp1)
         products.should include(lp2)
         products.should_not include(lp3)
       end

       it "returns products given some heels" do
         lp1 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, variant_id: basic_shoe_size_35.id, :heel => 4.5, :inventory => 1)
         lp2 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, variant_id: basic_shoe_size_40.id, :heel => 6.5, :inventory => 1)
         lp3 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, variant_id: basic_shoe_size_37.id, :subcategory_name => "melissa", :inventory => 1)
         params = {:id => liquidation.id, :heels => ["6.5", "4.5"]}
         products = LiquidationSearchService.new(params).search_products
         products.should include(lp1)
         products.should include(lp2)
         products.should_not include(lp3)
       end

       it "returns 0 products if dont have inventory" do
         lp1 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, :heel => 4.5, :inventory => 0)
         params = {:id => liquidation.id, :heels => ["6.5", "4.5"]}
         LiquidationSearchService.new(params).search_products.should == []
       end

       it "returns 0 products if the product is not visible" do
         basic_shoe_size_35.product.update_attributes(:is_visible => false)
         lp1 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, :heel => 4.5, :inventory => 1)
         params = {:id => liquidation.id, :heels => ["6.5", "4.5"]}
         LiquidationSearchService.new(params).search_products.should == []
       end
     end

     context "ordering" do
      it "should return only acessories" do
        lp2 = LiquidationProduct.create(:category_id => Category::ACCESSORY, :liquidation => liquidation, :product_id => basic_accessory_1.product.id, variant_id: basic_accessory_1.id, :subcategory_name => "pulseira", :inventory => 1)
        params = {:id => liquidation.id, :accessory_subcategories => ["pulseira", "lisa"], :heels => ["4.5"]}
        products = LiquidationSearchService.new(params).search_products
        products.should include(lp2)
      end
    end

    context "combined filters" do
      it "returns products given subcategories, shoe sizes and heels" do
        lp1 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, variant_id: basic_shoe_size_35.id, :subcategory_name => "rasteirinha", :inventory => 1, :shoe_size => "45", :heel => "5.6")
        lp2 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, variant_id: basic_shoe_size_40.id, :subcategory_name => "rasteirinha", :inventory => 1, :shoe_size => "45", :heel => "5.6")
        params = {:id => liquidation.id, :shoe_subcategories => ["rasteirinha"], :shoe_sizes => ["45"], :heels => ["5.6"]}
        products = LiquidationSearchService.new(params).search_products
        products.should include(lp1)
        products.should include(lp2)
      end

      it "returns products given subcategories and shoe sizes" do
        lp1 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, variant_id: basic_shoe_size_35.id, :subcategory_name => "rasteirinha", :inventory => 1, :shoe_size => "45")
        lp2 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, variant_id: basic_shoe_size_40.id, :subcategory_name => "rasteirinha", :inventory => 1, :shoe_size => "45")
        lp3 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, variant_id: basic_shoe_size_37.id, :subcategory_name => "rasteirinha", :inventory => 1, :shoe_size => "39")
        params = {:id => liquidation.id, :shoe_subcategories => ["rasteirinha"], :shoe_sizes => ["45"]}
        products = LiquidationSearchService.new(params).search_products
        products.should include(lp1)
        products.should include(lp2)
        products.should_not include(lp3)
      end

      it "returns products given subcategories and heels" do
        lp1 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, variant_id: basic_shoe_size_35.id, :subcategory_name => "rasteirinha", :inventory => 1, :heel => "5.6")
        lp2 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, variant_id: basic_shoe_size_40.id, :subcategory_name => "rasteirinha", :inventory => 1, :heel => "5.9")
        params = {:id => liquidation.id, :shoe_subcategories => ["rasteirinha"], :heels => ["5.6", "5.9"]}
        products = LiquidationSearchService.new(params).search_products
        products.should include(lp1)
        products.should include(lp2)
      end

      it "returns products given heels and shoe sizes" do
        lp1 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, variant_id: basic_shoe_size_35.id, :subcategory_name => "rasteirinha", :inventory => 1, :shoe_size => "37", :heel => "5.6")
        lp2 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, variant_id: basic_shoe_size_37.id, :subcategory_name => "melissa", :inventory => 1, :shoe_size => "37", :heel => "7.6")
        lp3 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, variant_id: basic_shoe_size_40.id, :subcategory_name => "melissa", :inventory => 1, :shoe_size => "37", :heel => "5.6")
        params = {:id => liquidation.id, :shoe_subcategories => ["melissa", "rasteirinha"], :shoe_sizes => ["37"], :heels => ["5.6"]}
        products = LiquidationSearchService.new(params).search_products
        products.should include(lp1)
        products.should include(lp3)
        products.should_not include(lp2)
      end

      it "returns only bags" do
        lp4 = LiquidationProduct.create(:category_id => Category::BAG, :liquidation => liquidation, :product_id => basic_bag_1.product.id, variant_id: basic_bag_1.id, :subcategory_name => "lisa", :inventory => 1)
        params = {:id => liquidation.id, :bag_subcategories => ["lisa"], :shoe_subcategories => ["melissa", "rasteirinha"], :shoe_sizes => ["37"], :heels => ["5.6"]}
        products = LiquidationSearchService.new(params).search_products
        # products.should include(lp1)
        # products.should include(lp3)
        products.should include(lp4)
        # products.should_not include(lp2)
      end

      it "returns products given heels and shoe sizes and bags and acessories" do
        pending("Check the new rule")
        lp1 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, variant_id: basic_shoe_size_35.id, :subcategory_name => "rasteirinha", :inventory => 1, :shoe_size => "37", :heel => "5.6")
        lp2 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, variant_id: basic_shoe_size_37.id, :subcategory_name => "melissa", :inventory => 1, :shoe_size => "37", :heel => "7.6")
        lp3 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, variant_id: basic_shoe_size_40.id, :subcategory_name => "melissa", :inventory => 1, :shoe_size => "37", :heel => "5.6")
        lp4 = LiquidationProduct.create(:category_id => Category::BAG, :liquidation => liquidation, :product_id => basic_bag_1.product.id, :subcategory_name => "lisa", :inventory => 1)
        lp5 = LiquidationProduct.create(:category_id => Category::ACCESSORY, :liquidation => liquidation, :product_id => basic_accessory_1.product.id, :subcategory_name => "pulseira", :inventory => 1)
        params = {:id => liquidation.id, :bag_accessory_subcategories => ["lisa", "pulseira"], :shoe_subcategories => ["melissa", "rasteirinha"], :shoe_sizes => ["37"], :heels => ["5.6"]}
        products = LiquidationSearchService.new(params).search_products
        products.should include(lp1)
        products.should include(lp3)
        products.should include(lp4)
        products.should include(lp5)
        products.should_not include(lp2)
      end

      it "returns products given heels and shoe sizes and bags, acessories and not invisible items" do
        pending("Check the new rule")
        lp1 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, variant_id: basic_shoe_size_35.id, :subcategory_name => "rasteirinha", :inventory => 1, :shoe_size => "37", :heel => "5.6")
        lp2 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, variant_id: basic_shoe_size_37.id, :subcategory_name => "melissa", :inventory => 1, :shoe_size => "37", :heel => "7.6")
        lp3 = LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, variant_id: basic_shoe_size_40.id, :subcategory_name => "melissa", :inventory => 1, :shoe_size => "37", :heel => "5.6")
        lp4 = LiquidationProduct.create(:category_id => Category::BAG, :liquidation => liquidation, :product_id => basic_bag_1.product.id, :subcategory_name => "lisa", :inventory => 1)

        basic_accessory_1.product.update_attributes(:is_visible => false)

        lp5 = LiquidationProduct.create(:category_id => Category::ACCESSORY, :liquidation => liquidation, :product_id => basic_accessory_1.product.id, :subcategory_name => "pulseira", :inventory => 1)
        params = {:id => liquidation.id, :bag_accessory_subcategories => ["lisa", "pulseira"], :shoe_subcategories => ["melissa", "rasteirinha"], :shoe_sizes => ["37"], :heels => ["5.6"]}
        products = LiquidationSearchService.new(params).search_products
        products.should include(lp1)
        products.should include(lp3)
        products.should include(lp4)
        products.should_not include(lp2)
        products.should_not include(lp5)
      end
    end
  end
end
