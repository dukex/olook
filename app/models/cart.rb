# -*- encoding : utf-8 -*-
class Cart < ActiveRecord::Base
  DEFAULT_QUANTITY = 1
  
  belongs_to :user
  has_one :order
  has_many :cart_items
  
  attr_accessor :gift_wrap
  attr_accessor :used_coupon
  attr_accessor :used_promotion
  attr_accessor :freight
  attr_accessor :address
  attr_accessor :credits
  attr_accessor :gift
  
  #TODO: refactor this to include price as a parameter
  def add_variant(variant, quantity=nil)
    quantity ||= Cart::DEFAULT_QUANTITY.to_i
    quantity = quantity.to_i
    if variant.available_for_quantity?(quantity)
      current_item = cart_items.select { |item| item.variant == variant }.first
      if current_item
        current_item.update_attributes(:quantity => quantity)
      else
        #ACCESS PRODUCT IN PRICES TO ACCESS MASTER VARIANT
        current_item =  CartItem.new(:cart_id => id,
                                     :variant_id => variant.id,
                                     :quantity => quantity,
                                     :price => variant.product.price,
                                     :retail_price => variant.product.retail_price,
                                     :discount_source => :legacy
                                     )
        cart_items << current_item
      end
      current_item
    end
  end

  def remove_variant(variant)
    current_item = cart_items.select { |item| item.variant == variant }.first
    current_item.destroy if current_item
  end
  
  def cart_items_total
    cart_items.sum(:quantity)
  end
  
  def gift_wrap?
    gift_wrap == "1" ? true : false
  end
  
  def total
    PriceModificator.new(self).final_price
  end
  
  def freight_price
    0
  end
  
  def coupon_discount
    PriceModificator.new(self).discounts[:coupon][:value]
  end
  
  def credits_discount
    PriceModificator.new(self).discounts[:credits][:value]
  end
  
  def promotion_discount
    PriceModificator.new(self).discounts[:promotion][:value]
  end
end