# -*- encoding : utf-8 -*-
class Cart < ActiveRecord::Base
  serialize :payment_data, Hash
  DEFAULT_QUANTITY = 1

  belongs_to :user
  belongs_to :coupon
  belongs_to :address
  belongs_to :shipping_service
  has_many :orders
  has_many :items, :class_name => "CartItem", :dependent => :destroy

  attr_accessor :coupon_code

  validates_with CouponValidator, :attributes => [:coupon_code]

  before_validation :update_coupon
  after_update :notify_listener

  def self.find_saved_for_user(user, attrs)
    cart = nil
    if user
      id = attrs[:params] || attrs[:session]
      sql = self.where(user_id: user.id)
      cart = sql.find_by_id(id) if id
      # cart ||= sql.last
    end
    cart = Cart.find_by_id(attrs[:session]) if attrs[:session]
    cart
  end

  def self.gift_wrap_price
    YAML::load_file(Rails.root.to_s + '/config/gifts.yml')["values"][0]
  end

  def api_hash
    {
      id: id,
      user_id: user_id,
      address_id: address_id,
      address: address.try(:api_hash),
      use_credits: use_credits,
      facebook_share_discount: facebook_share_discount,
      coupon_code: coupon.try(:code),
      items_count: items.count,
      items_subtotal: cart_calculator.items_subtotal,
      subtotal: cart_calculator.subtotal,
      items: items.map { |item| item.api_hash },
      freights: freights,
      shipping_service_id: shipping_service_id,
      gift_wrap: gift_wrap,
      gift_wrap_value: Cart.gift_wrap_price,
      payment_method: payment_method,
      payment_data: payment_data,
      payment: Api::V1::PaymentType.find(payment_method),
      discounts: cart_calculator.items_discount,
      payment_discounts: - cart_calculator.payment_discounts,
      credits:  - cart_calculator.used_credits_value,
      total: cart_calculator.items_total
    }
  end

  def freights
    if address
      zip_code = address.zip_code.gsub(/\D/, '').to_i
      transport_shippings = FreightService::TransportShippingManager.new(
        zip_code, cart_calculator.items_subtotal, Shipping.with_zip(zip_code)).api_hash
      if(shipping_service_id)
        transport_shippings.select! { |t| t[:shipping_service_id] == shipping_service_id }
      end
      transport_shippings
    else
      []
    end
  end

  def selected_freight
    freights.find { |f| f[:shipping_service_id] == shipping_service_id }
  end

  def cart_calculator
    @cart_calculator ||= CartProfit::CartCalculator.new(self)
  end

  def allow_credit_payment?
    has_empty_adjustments? && has_any_full_price_item? && self.sub_total >= 100
  end

  def add_variants(variant_numbers)
    variants = Variant.where("number in (?)", variant_numbers)
    variants.each { |v| add_item(v) }
  end

  def add_item(variant, quantity=nil, gift_position=0, gift=false)
    #BLOCK ADD IF IS NOT GIFT AND HAS GIFT IN CART
    return nil if self.has_gift_items? && !gift

    quantity = quantity.to_i == 0 ? Cart::DEFAULT_QUANTITY : quantity.to_i

    return nil unless variant.available_for_quantity?(quantity)

    current_item = items.select { |item| item.variant == variant }.first
    if current_item
      current_item.update_attributes(:quantity => quantity)
    else
      current_item =  CartItem.new(:cart_id => id,
                                   :variant_id => variant.id,
                                   :quantity => quantity,
                                   :gift_position => gift_position,
                                   :gift => gift
                                   )
      items << current_item
    end

    current_item
  end

  def items_total
   items.sum(:quantity)
  end

  def clear
    items.destroy_all
  end

  def has_gift_items?
    items.where(:gift => true).count > 0
  end

  def remove_unavailable_items
    unavailable_items = []
    items.each do |li|
      variant = Variant.lock("FOR UPDATE").find(li.variant.id)
      unavailable_items << li unless variant.available_for_quantity? li.quantity
    end
    size_items = unavailable_items.size
    unavailable_items.each {|item| item.destroy}
    size_items
  end

  def total_promotion_discount
    items.inject(0) {|sum, item| /Promotion:/ =~ item.cart_item_adjustment.source ? sum + item.adjustment_value : 0 }
  end

  def total_liquidation_discount(options={})
    items.inject(0) do |sum, item|
      liquidation_discount = item.adjustment_value > 0 ? 0 : item.price - item.retail_price(options)
      sum + liquidation_discount
    end
  end

  def total_coupon_discount
    items.inject(0) {|sum, item| /Coupon:/ =~ item.cart_item_adjustment.source ? sum + item.adjustment_value : 0 }
  end

  def total_price
    items.inject(0) { |total, item| total += item.quantity * item.price }
  end

  def sub_total
    cart_calculator.items_subtotal
  end

  def remove_coupon!
    self.coupon_id = nil
    self.coupon_code = nil
    self.save!
    self.reload
  end

  # CONSIDER to change this method name
  def increment_from_gift_wrap
    gift_wrap ? CartService.gift_wrap_price : 0
  end

  def has_appliable_percentage_coupon?
    coupon && coupon.is_percentage? && items.select{|item| coupon.apply_discount_to?(item.product)}.any?
  end

  def has_coupon?
    coupon.present? && (!coupon.is_percentage? || has_appliable_percentage_coupon?)
  end

  def complete_look_product_ids_in_cart
    return_array = []
    items.each do |item|
      return_array |= item.product.look_product_ids if item.product.list_contains_all_complete_look_products?(items.map{|i| i.product.id})
    end
    Set.new return_array
  end

  def as_json options
    super(:include =>
      {
        :coupon => {:only => [:is_percentage, :value]},
        :items =>
        {
          :methods => [:formatted_product_name, :thumb_picture, :retail_price, :description, :name],
          :only => [:quantity, :formatted_product_name, :thumb_picture, :retail_price, :description, :id, :name]
        }
      }, :methods => [:items_total],
      :only => [:coupon, :items, :items_total])
  end

  def uncheck_credit_usage_if_unallowed
    self.update_attribute(:use_credits, can_use_credits?)
  end

  def can_use_credits?
    self.use_credits && self.allow_credit_payment?
  end

  def sub_total_with_markdown
    cart_calculator.items_subtotal true
  end  

  private

    def update_coupon
      if self.coupon_code == ''
        self.coupon_id = nil
        self.coupon_code = nil
      end
      if self.coupon_id
        self.coupon_code = self.coupon.code
      elsif self.coupon_code
        _coupon = Coupon.find_by_code(self.coupon_code)
        _user_coupon = user.nil? ? nil : user.user_coupon
        if UniqueCouponUtilizationPolicy.apply?(coupon: _coupon, user_coupon: _user_coupon)
          self.coupon = _coupon
        end
      end
    end

    def notify_listener
      PromotionListener.update(self)
    end

    def has_any_full_price_item?
      items.select { |item| item.price == item.retail_price }.any?
    end

    def has_empty_adjustments?
      items.select { |item| item.has_adjustment? }.empty?
    end

end
