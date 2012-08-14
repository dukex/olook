require "spec_helper"

describe CartService do

  let(:gift_wrap_price) { 5.00 }

  let(:user) { FactoryGirl.create :user }
  let(:address) { FactoryGirl.create(:address, :user => user) }
  let(:cart) { FactoryGirl.create(:cart_with_items, :user => user) }
  let(:shipping_service) { FactoryGirl.create :shipping_service }
  let(:freight) { { :price => 12.34, :cost => 2.34, :delivery_time => 2, :shipping_service_id => shipping_service.id, :address_id => address.id} }
  let(:promotion) { FactoryGirl.create :first_time_buyers }
  let(:coupon_of_value) { FactoryGirl.create :standard_coupon}
  let(:coupon_of_percentage) { FactoryGirl.create :percentage_coupon}
  let(:payment) { FactoryGirl.create :debit }
  let(:cart_service) { CartService.new({
    :cart => cart,
    :freight => freight,
  }) }
  
  
  it "should return gift wrap price" do
    CartService.gift_wrap_price.should eq(gift_wrap_price)
  end
  
  context "when initialize" do
    it "should set credits to zero when is not supplied" do
      cart_service = CartService.new({})
      cart_service.credits.should eq(0)
    end

    [:cart, :gift_wrap, :coupon, :promotion, :freight, :credits].each do |attribute|
      it "should set #{attribute}" do
        value = mock
        cart_service = CartService.new({attribute => value})
        cart_service.send("#{attribute}").should be(value)
      end
    end
  end
  
  context ".gift_wrap?" do
    it "should return true when gift_wrap is '1'" do
      cart_service = CartService.new({:gift_wrap => '1'})
      cart_service.gift_wrap?.should eq(true)
    end
    
    it "should return false when gift_wrap has any value" do
      cart_service = CartService.new({:gift_wrap => 'anything'})
      cart_service.gift_wrap?.should eq(false)
    end
    
    it "should return false when gift_wrap is nil" do
      cart_service = CartService.new({})
      cart_service.gift_wrap?.should eq(false)
    end
  end
  
  context ".freight_price" do
    it "should return zero when freight is not available" do
      cart_service = CartService.new({})
      cart_service.freight_price.should eq(0)
    end
    
    it "should return zero when price is not available" do
      cart_service = CartService.new({:freight => {}})
      cart_service.freight_price.should eq(0)
    end
    
    it "should return price" do
      cart_service = CartService.new({:freight => {:price => 10.0}})
      cart_service.freight_price.should eq(10.0)
    end
  end
  
  context ".freight_city" do
    it "should return empty when freight is not available" do
      cart_service = CartService.new({})
      cart_service.freight_city.should eq("")
    end
    
    it "should return empty when city is not available" do
      cart_service = CartService.new({:freight => {}})
      cart_service.freight_city.should eq("")
    end
    
    it "should return city" do
      cart_service = CartService.new({:freight => {:city => "XPTO2.0"}})
      cart_service.freight_city.should eq("XPTO2.0")
    end
  end

  context ".freight_state" do
    it "should return empty when freight is not available" do
      cart_service = CartService.new({})
      cart_service.freight_state.should eq("")
    end
    
    it "should return empty when state is not available" do
      cart_service = CartService.new({:freight => {}})
      cart_service.freight_state.should eq("")
    end
    
    it "should return state" do
      cart_service = CartService.new({:freight => {:state => "XPTO"}})
      cart_service.freight_state.should eq("XPTO")
    end
  end
  
  context ".item_price" do
    it "should return price from master variant" do
      cart.items.first.variant.product.master_variant.update_attribute(:price, 20)
      cart_service.item_price(cart.items.first).should eq(20)
    end
  end
  
  context ".item_retail_price" do
    before :each do
      cart.items.first.variant.product.master_variant.update_attribute(:price, 20)
    end
    
    it "should return retail price from master variant" do
      cart.items.first.variant.product.master_variant.update_attribute(:retail_price, 18)
      cart_service.item_retail_price(cart.items.first).should eq(18)
    end
    
    context "when has coupon of percentage" do
      it "should return current retail price if discount price is less than current" do
        cart.items.first.variant.product.master_variant.update_attribute(:retail_price, 14)
        cart_service.coupon = coupon_of_percentage
        cart_service.item_retail_price(cart.items.first).should eq(14)
      end
      
      it "should return discount price if discount price is greater than current" do
        cart.items.first.variant.product.master_variant.update_attribute(:retail_price, 18)
        cart_service.coupon = coupon_of_percentage
        cart_service.item_retail_price(cart.items.first).should eq(16)
      end
    end

    context "when has promotion" do
      it "should return current retail price if discount price is less than current" do
        cart.items.first.variant.product.master_variant.update_attribute(:retail_price, 10)
        cart_service.promotion = promotion
        cart_service.item_retail_price(cart.items.first).should eq(10)
      end
      
      it "should return discount price if discount price is greater than current" do
        cart.items.first.variant.product.master_variant.update_attribute(:retail_price, 18)
        cart_service.coupon = coupon_of_percentage
        cart_service.promotion = promotion
        cart_service.item_retail_price(cart.items.first).should eq(14)
      end
    end
    
    context "when item is gift" do
      it "should return gift price for gift position" do
        cart.items.first.variant.product.master_variant.update_attribute(:retail_price, 10)
        cart.items.first.update_attribute(:gift, true)
        Product.any_instance.stub(:gift_price => 14)
        cart_service.item_retail_price(cart.items.first).should eq(14)
      end
    end
  end
  
  context ".item_promotion?" do
    it "should return true if retail_price is different of price"
    it "should return false if retail_price is equal price"
  end
  
  context ".item_price_total" do
    it "should return item_price muliply by item quantity"
  end
  
  context ".item_retail_price_total" do
    it "should return item_retail_price muliply by item quantity"
  end
  
  context ".item_discount_percent" do
    it "should return zero percent when has no discounts"
    
    it "should return percent when has olooklet"
    
    it "should return percent when has coupon of percentage"

    it "should return percent when has promotion"

    it "should return percent when item is gift"
  end
  
  context ".item_discount_origin" do
    it "should return empty when has no discounts"
    
    it "should return olooklet description when has olooklet"
    
    it "should return coupon description when has coupon of percentage"

    it "should return promotion description when has promotion"

    it "should return gift description when item is gift"
  end
  
  context ".item_discount_origin_type" do
    it "should return empty when has no discounts"
    
    it "should return olooklet when has olooklet"
    
    it "should return coupon when has coupon of percentage"

    it "should return promotion when has promotion"

    it "should return gift when item is gift"
  end
  
  context ".item_discounts" do
    it "should return empty when has no discounts"
    
    it "should return olooklet when has olooklet"
    
    it "should return coupon when has coupon of percentage"

    it "should return promotion when has promotion"

    it "should return gift when item is gift"
  end
  
  context ".item_has_more_than_one_discount?" do
    it "should return false when has no discount"
    it "should return false when has one discount"
    it "should return true when has two or more discounts"
  end
  
  context ".subtotal" do
    it "should return sum of price_total for all items"
    it "should return sum of retail_price_total for all items"
  end
  
  context ".total_increase" do
    it "should return zero when no has freight and gift wrap" do
      cart_service = CartService.new({})
      cart_service.total_increase.should eq(0)
    end
    
    it "should sum gift wrap" do
      cart_service = CartService.new({:gift_wrap => '1'})
      cart_service.total_increase.should eq(gift_wrap_price)
    end
    
    it "should sum freight price" do
      cart_service = CartService.new({:freight => {:price => 10.0}})
      cart_service.total_increase.should eq(10.0)
    end
  end
  
  context ".total_coupon_discount"
  context ".total_credits_discount"
  context ".total_discount"
  context ".is_minimum_payment?"
  context ".total_discount_by_type"
  context ".item_discounts"
  context ".active_discounts"
  context ".has_more_than_one_discount?"
  context ".total"
  
  context "insert a order" do
    it "should a valid cart is required" do
      expect {
        CartService.new({}).generate_order!(double(Payment))
      }.to raise_error(ActiveRecord::RecordNotFound, 'A valid cart is required for generating an order.')
    end
    
    it "should a valid freight is required" do
      expect {
        CartService.new({:cart => cart}).generate_order!(double(Payment))
      }.to raise_error(ActiveRecord::RecordNotFound, 'A valid freight is required for generating an order.')
    end
    
    it "should a valid user is required" do
      expect {
        cart.user = nil
        CartService.new({:cart => cart, :freight => freight}).generate_order!(double(Payment))
      }.to raise_error(ActiveRecord::RecordNotFound, 'A valid user is required for generating an order.')
    end
    
    it "should create" do
      expect {
        cart_service = CartService.new({:cart => cart, :freight => freight})
        cart_service.stub(:total_credits_discount => 0)
        cart_service.stub(:total_discount => 10)
        cart_service.stub(:total_increase => 20)
        cart_service.stub(:total => 30)
        cart_service.stub(:subtotal => 40)
        cart_service.stub(:item_price => 10)
        cart_service.stub(:item_retail_price => 20)
        
        order = cart_service.generate_order!(payment)
        
        order.cart.should eq(cart)
        order.payment.should eq(payment)
        order.credits.should eq(0)
        order.user_id.should eq(user.id)
        order.restricted.should eq(false)
        order.gift_wrap.should eq(false)
        order.amount_discount.should eq(10)
        order.amount_increase.should eq(20)
        order.amount_paid.should eq(30)
        order.subtotal.should eq(40)
        order.user_first_name.should eq(user.first_name)
        order.user_last_name.should eq(user.last_name)
        order.user_email.should eq(user.email)
        order.user_cpf.should eq(user.cpf)
        
        cart.items.map do |item|
          line_item = order.line_items.where(
            :variant_id => item.variant.id, 
            :quantity => item.quantity, 
            :gift => item.gift
          ).first
          line_item.price.should eq(10)
          line_item.retail_price.should eq(20)
        end

        freight.each do |key, value|
          order.freight.send("#{key}").should eq(value)
        end
        
      }.to change{Order.count}.by(1)
    end
    
    it "should create a promotion when used" do
      expect {
        cart_service = CartService.new({:cart => cart, :freight => freight, :promotion => promotion})
        
        cart_service.stub(:total_discount_by_type => 20)
        
        order = cart_service.generate_order!(payment)
        
        order.used_promotion.promotion.should be(promotion)
        order.used_promotion.discount_percent.should be(promotion.discount_percent)
        order.used_promotion.discount_value.should eq(20)
        
      }.to change{Order.count}.by(1)
    end
    
    it "should create a coupon when used" do
      expect {
        cart_service = CartService.new({:cart => cart, :freight => freight, :coupon => coupon_of_value})
        cart_service.stub(:total_coupon_discount => 100)
        order = cart_service.generate_order!(payment)
        order.used_coupon.coupon.should be(coupon_of_value)
      }.to change{Order.count}.by(1)
    end
  end
end