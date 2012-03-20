require 'spec_helper'

describe LiquidationProductService do
  let(:liquidation) { FactoryGirl.create(:liquidation) }
  
  before :each do
    Liquidation.delete_all
    LiquidationProduct.delete_all
    Product.delete_all
  end

  def products_ids
    Product.all.map(&:id).join(",").sav
  end

  def mock_variant size
    variant = mock Variant
    variant.stub(:description).and_return(size)
    variant
  end

  def mock_detail token
    detail = mock Detail
    detail.stub(:translation_token).and_return(token)
    detail
  end
  
  describe "number of rows" do
    it "should insert one row per shoe size for the same shoe" do
      FactoryGirl.create(:basic_shoe_size_40)
      FactoryGirl.create(:basic_shoe_size_37, :product => Product.last)
      Variant.count.should == 2
      Product.count.should == 1
      expect {
        LiquidationProductService.new(liquidation, Product.last, 50).save
      }.to change(LiquidationProduct, :count).by(2)
    end
    
    it "should insert only 1 row for products that are not shoes" do
      product = FactoryGirl.create(:basic_bag)
      expect {
         LiquidationProductService.new(liquidation, product, 50).save
      }.to change(LiquidationProduct, :count).by(1)
    end
  end


  it "should calculate the retail price based on the discount percent" do
    product = mock Product
    product.stub(:price).and_return 100.90
    LiquidationProductService.new(liquidation, product, 50).retail_price.should == BigDecimal("50.45")
  end
  
  describe "update" do
    it "should update the price for all variants" do
      FactoryGirl.create(:basic_shoe_size_35)
      product = Product.last
      FactoryGirl.create(:basic_shoe_size_37, :product => product)      
      LiquidationProductService.new(liquidation, product, 10).save
      LiquidationProduct.all.map{|lp| lp.discount_percent }.should == [10, 10]
    end
  end

end
