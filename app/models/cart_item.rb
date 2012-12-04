# -*- encoding : utf-8 -*-
class CartItem < ActiveRecord::Base
  belongs_to :cart
  belongs_to :variant

  delegate :product, :to => :variant, :prefix => false
  delegate :name, :to => :variant, :prefix => false
  delegate :description, :to => :variant, :prefix => false
  delegate :thumb_picture, :to => :variant, :prefix => false
  delegate :color_name, :to => :variant, :prefix => false



  def product_quantity
    deafult_quantity = [1]
    is_suggested_product? ? suggested_product_quantity : deafult_quantity
  end  

  def price 
    variant.product.price
  end

  def retail_price
    variant.product.retail_price
  end

  private 
    def suggested_product_quantity
      Setting.quantity_for_sugested_product.to_a
    end

    def is_suggested_product? 
      product.id == Setting.checkout_suggested_product_id.to_i      
    end
end
