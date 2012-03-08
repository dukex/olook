require 'spec_helper'

describe LiquidationsController do

  describe "GET 'show'" do

    let(:basic_shoe_size_35) { FactoryGirl.create(:basic_shoe_size_35) }
    let(:basic_shoe_size_37) { FactoryGirl.create(:basic_shoe_size_37) }
    let(:basic_shoe_size_40) { FactoryGirl.create(:basic_shoe_size_40) }

    let(:basic_bag) { FactoryGirl.create(:basic_bag) }
    let(:basic_accessory) { FactoryGirl.create(:basic_accessory) }

    let(:basic_bag_1) { FactoryGirl.create(:basic_bag_simple, :product => basic_bag) }
    let(:basic_accessory_1) { FactoryGirl.create(:basic_accessory_simple, :product => basic_accessory) }

    let(:liquidation) { FactoryGirl.create(:liquidation) }

    it "returns http success" do
      get 'show', :id => 1
      response.should be_success
    end

    context "isolated filters" do
      it "returns products given some subcategories" do
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, :subcategory_name => "rasteirinha")
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, :subcategory_name => "melissa")
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, :heel => 5.6)
        get :show, :id => 2, :subcategories => ["rasteirinha", "melissa"]
        assigns(:products).should == [basic_shoe_size_35.product, basic_shoe_size_40.product]
      end

      it "returns products given some shoe sizes" do
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, :shoe_size => 45)
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, :shoe_size => 35)
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, :heel => 5.6)
        get :show, :id => 2, :shoe_sizes => ["45", "35"]
        assigns(:products).should == [basic_shoe_size_35.product, basic_shoe_size_40.product]
      end

      it "returns products given some heels" do
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, :heel => 4.5)
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, :heel => 6.5)
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, :subcategory_name => "melissa")
        get :show, :id => 2, :heels => ["6.5", "4.5"]
        assigns(:products).should == [basic_shoe_size_35.product, basic_shoe_size_40.product]
      end
    end

    context "ordering" do
      it "should return the order: shoes, bags and acessories" do
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, :heel => 4.5)
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_accessory_1.product.id, :subcategory_name => "pulseira")
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_bag_1.product.id, :subcategory_name => "lisa")
        get :show, :id => 2, :subcategories => ["pulseira", "lisa"], :heels => ["4.5"]
        assigns(:products).should == [basic_shoe_size_35.product, basic_bag_1.product, basic_accessory_1.product]
      end
    end

    context "combined filters" do
      it "returns products given subcategories, shoe sizes and heels" do
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, :subcategory_name => "rasteirinha")
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, :shoe_size => "45")
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, :heel => 5.6)
        get :show, :id => 2, :subcategories => ["rasteirinha"], :shoe_sizes => ["45"], :heels => ["5.6"]
        assigns(:products).should == [basic_shoe_size_35.product, basic_shoe_size_40.product, basic_shoe_size_37.product]
      end

      it "returns products given subcategories and shoe sizes" do
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, :subcategory_name => "rasteirinha")
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, :shoe_size => "45")
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, :heel => 5.6)
        get :show, :id => 2, :subcategories => ["rasteirinha"], :shoe_sizes => ["45"]
        assigns(:products).should == [basic_shoe_size_35.product, basic_shoe_size_40.product]
      end

      it "returns products given subcategories and heels" do
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, :subcategory_name => "rasteirinha")
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, :shoe_size => "45")
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, :heel => 5.6)
        get :show, :id => 2, :subcategories => ["rasteirinha"], :heels => ["5.6"]
        assigns(:products).should == [basic_shoe_size_35.product, basic_shoe_size_37.product]
      end

      it "returns products given heels and shoe sizes" do
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_35.product.id, :subcategory_name => "rasteirinha")
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_40.product.id, :shoe_size => "45")
        LiquidationProduct.create(:liquidation => liquidation, :product_id => basic_shoe_size_37.product.id, :heel => 5.6)
        get :show, :id => 2, :shoe_sizes => ["45"], :heels => ["5.6"]
        assigns(:products).should == [basic_shoe_size_40.product, basic_shoe_size_37.product]
      end
    end
  end
end
