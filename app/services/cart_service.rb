# -*- encoding : utf-8 -*-
class CartService
  attr_accessor :cart
  attr_accessor :coupon
  attr_accessor :promotion
  attr_accessor :freight
  
  def allow_credit_payment?
    promotion.nil? && cart.allow_credit_payment? 
  end

  def self.gift_wrap_price
    YAML::load_file(Rails.root.to_s + '/config/gifts.yml')["values"][0]
  end

  def initialize(params)
    params.each_pair do |key, value|
      self.send(key.to_s+'=',value)
    end
  end

  def freight_price
    freight && freight.fetch(:price, 0) || 0
  end

  def freight_city
    freight && freight.fetch(:city, "") || ""
  end

  def freight_state
    freight && freight.fetch(:state, "") || ""
  end

  def item_price(item)
    get_retail_price_for_item(item).fetch(:price)
  end

  def item_retail_price(item)
    get_retail_price_for_item(item).fetch(:retail_price)
  end

  def item_promotion?(item)
    item_price(item) != item_retail_price(item)
  end

  def item_price_total(item)
    item_price(item) * item.quantity
  end

  def item_retail_price_total(item)
    item_retail_price(item) * item.quantity
  end

  def item_discount_percent(item)
    get_retail_price_for_item(item).fetch(:percent)
  end

  def item_discount_origin(item)
    get_retail_price_for_item(item).fetch(:origin)
  end

  def item_discount_origin_type(item)
    get_retail_price_for_item(item).fetch(:origin_type)
  end

  def item_discounts(item)
    get_retail_price_for_item(item).fetch(:discounts)
  end

  def subtotal(type = :retail_price)
    return 0 if cart.nil? || (cart && cart.items.nil?)
    cart.items.inject(0) do |value, item|
      value += self.send("item_#{type}_total", item)
    end
  end

  def total_increase
    increase = 0
    increase += increment_from_gift_wrap
    increase += freight_price
    increase
  end

  def total_coupon_discount
    calculate_discounts.fetch(:total_coupon)
  end

  def total_credits_discount
    calculate_discounts.fetch(:total_credits)
  end

  def total_discount
    calculate_discounts.fetch(:total_discount)
  end

  def is_minimum_payment?
    calculate_discounts.fetch(:is_minimum_payment)
  end

  def total_discount_by_type(type)
    total_value = 0
    total_value += total_coupon_discount if :coupon == type
    total_value += calculate_discounts.fetch(:total_credits_by_invite) if :credits_by_invite == type
    total_value += calculate_discounts.fetch(:total_credits_by_redeem) if :credits_by_redeem == type
    total_value += calculate_discounts.fetch(:total_credits_by_loyalty_program) if :credits_by_loyalty_program == type

    cart.items.each do |item|
      if item_discount_origin_type(item) == type
        total_value += (item_price(item) - item_retail_price(item))
      end
    end

    total_value
  end

  def active_discounts
    discounts = cart.items.inject([]) do |discounts, item|
      discounts + item_discounts(item)
    end

    discounts.uniq
  end

  def has_more_than_one_discount?
    active_discounts.size > 1
  end

  def total
    total = subtotal(:retail_price)
    total += total_increase
    total -= total_discount

    total = Payment::MINIMUM_VALUE if total < Payment::MINIMUM_VALUE
    total
  end

  def gross_amount
    self.subtotal(:price) + self.total_increase
  end

  def generate_order!(gateway, tracking = nil)
    raise ActiveRecord::RecordNotFound.new('A valid cart is required for generating an order.') if cart.nil?
    raise ActiveRecord::RecordNotFound.new('A valid freight is required for generating an order.') if freight.nil?
    raise ActiveRecord::RecordNotFound.new('A valid user is required for generating an order.') if cart.user.nil?

    user = cart.user

    order = Order.create!(
      :cart_id => cart.id,
      :user_id => user.id,
      :restricted => cart.has_gift_items?,
      :gift_wrap => cart.gift_wrap,
      :amount_discount => total_discount,
      :amount_increase => total_increase,
      :amount_paid => total,
      :subtotal => subtotal,
      :user_first_name => user.first_name,
      :user_last_name => user.last_name,
      :user_email => user.email,
      :user_cpf => user.cpf,
      :gross_amount => self.gross_amount,
      :gateway => gateway,
      :tracking => tracking
    )

    order.line_items = []

    cart.items.each do |item|

      order.line_items << LineItem.new(variant_id: item.variant.id, quantity: item.quantity, price: item_price(item),
                    retail_price: normalize_retail_price(order, item), gift: item.gift)

      create_freebies_line_items_and_update_subtotal(order, item)
    end

    order.freight = Freight.create(freight)

    order.save
    order
  end

  def normalize_retail_price(order, cart_item)
    retail_price = item_retail_price(cart_item)
    if retail_price == 0
      retail_price = 0.1
      order.amount_discount += retail_price
      order.subtotal += retail_price
    end
    retail_price
  end

  def create_freebies_line_items_and_update_subtotal(order, item)
    freebies = FreebieVariant.where(variant_id: item.variant.id).map { |freebie_variant| LineItem.new( variant_id: freebie_variant.freebie.id,
              quantity: item.quantity, price: 0.1, retail_price: 0.1, gift: item.gift, is_freebie: true) }
    order.line_items << freebies
    order.amount_discount += (freebies.size * 0.1)
    order.subtotal += (freebies.size * 0.1)
  end

  def amount_for_loyalty_program
    LoyaltyProgramCreditType.apply_percentage(total + total_discount_by_type(:credits_by_redeem))
  end

  def should_apply_promotion_discount?
    if has_promotion_and_coupon?
      strategy = promotion.load_strategy(promotion, cart.user)
      promotion_discount = strategy.calculate_promotion_discount(cart.items)
      if coupon.is_percentage?
        return promotion_discount[:percent] > coupon.value
      else
        return promotion_discount[:value] > coupon.value
      end
    end

    return true if promotion
  end

  # private
    def has_promotion_and_coupon?
      promotion && coupon
    end

  #TODO: add expiration logic
  def get_retail_price_for_item(item)
    origin = ''
    percent = 0
    final_retail_price = item.retail_price
    price = item.price
    discounts = []
    origin_type = ''

    if price != final_retail_price
      percent =  (1 - (final_retail_price / price) )* 100
      origin = 'Olooklet: '+percent.ceil.to_s+'% de desconto'
      discounts << :olooklet
      origin_type = :olooklet
    end

    coupon = self.coupon

    if coupon && !coupon.is_percentage?
      discounts << :coupon_of_value
    end

    if coupon && coupon.is_percentage? && coupon.apply_discount_to?(item.product.id) && item.product.can_supports_discount?
      discounts << :coupon
      coupon_value = price - ((coupon.value * price) / 100)
      if coupon_value < final_retail_price && !should_apply_promotion_discount?
        percent = coupon.value
        final_retail_price = coupon_value
        origin = 'Desconto de '+percent.ceil.to_s+'% do cupom '+coupon.code
        origin_type = :coupon
      end
    end

    promotion = self.promotion
    if promotion && item.product.can_supports_discount?
      discounts << :promotion
      strategy = promotion.load_strategy(promotion, cart.user)
      promotion_value = strategy.calculate_value(cart.items, item)
      # Do not allow Promotion discount if the user enters a coupon code
      if promotion_value < final_retail_price && should_apply_promotion_discount?
        final_retail_price = promotion_value 
        percent = promotion.discount_percent
        origin = 'Desconto de '+percent.ceil.to_s+'% '+promotion.banner_label
        origin_type = :promotion
      end
    end

    {
      :origin       => origin,
      :price        => price,
      :retail_price => final_retail_price,
      :percent      => percent,
      :discounts    => discounts,
      :origin_type  => origin_type
    }
  end

  def increment_from_gift_wrap
    cart.gift_wrap ? CartService.gift_wrap_price : 0
  end

  def minimum_value
    return 0 if freight_price > Payment::MINIMUM_VALUE
    Payment::MINIMUM_VALUE
  end

  #TODO
  def calculate_discounts
    discounts = []
    retail_value = self.subtotal(:retail_price) - minimum_value
    retail_value = 0 if retail_value < 0
    total_discount = 0

    coupon_value = self.coupon.value if self.coupon && !self.coupon.is_percentage?
    coupon_value = 0 if should_apply_promotion_discount?
    coupon_value ||= 0

    if coupon_value >= retail_value
      coupon_value = retail_value
    end

    retail_value -= coupon_value

    use_credits = self.cart.use_credits
    credits_loyality = 0
    credits_invite = 0
    credits_redeem = 0
    if (use_credits == true)
      #GET FROM loyality

      # Use loyalty only if there is no product with olooklet discount in the cart
      credits_loyality = allow_credit_payment? ? self.cart.user.user_credits_for(:loyalty_program).total : 0
      if credits_loyality >= retail_value
        credits_loyality = retail_value
      end

      retail_value -= credits_loyality

      #GET FROM INVITE
      credits_invite = allow_credit_payment? ? self.cart.user.user_credits_for(:invite).total : 0
      if credits_invite >= retail_value
        credits_invite = retail_value
      end

      retail_value -= credits_invite

      #GET FROM REDEEM
      credits_redeem = self.cart.user.user_credits_for(:redeem).total
      if credits_redeem >= retail_value
        credits_redeem = retail_value
      end

      retail_value -= credits_redeem

    end
    total_credits = credits_loyality + credits_invite + credits_redeem

    discounts << :coupon unless coupon_value < 0

    {
      :discounts                         => discounts,
      :is_minimum_payment                => (minimum_value > 0 && retail_value <= 0),
      :total_discount                    => (coupon_value + total_credits),
      :total_coupon                      => coupon_value,
      :total_credits_by_loyalty_program  => credits_loyality,
      :total_credits_by_invite           => credits_invite,
      :total_credits_by_redeem           => credits_redeem,
      :total_credits                     => total_credits
    }
  end


end
