# -*- encoding : utf-8 -*-
class PaymentBuilder
  attr_accessor :cart_service, :payment, :delivery_address, :response, :gateway_strategy

  def initialize(opts = { })
    @cart_service = opts[:cart_service]
    @payment = opts[:payment]
    @gateway_strategy = opts[:gateway_strategy]
    @tracking_params = opts[:tracking_params]
    log("Initializing Payment with #{opts.inspect}")
  end

  def create_payment_for(total_paid, payment_class, opts=nil)
    if should_create_payment_for?(total_paid)
      log("Creating Payment for #{payment_class} with total_paid: #{total_paid} and options: #{opts}")
      create_payment(total_paid, payment_class, opts)
    end
  end

  def should_create_payment_for?(value)
    value > 0
  end

  def create_payment(total_paid, payment_class, opts)
    options = opts || {}

    attributes = {
      total_paid: total_paid,
      order: payment.order,
      user_id: payment.user_id,
      cart_id: @cart_service.cart.id
    }

    attributes.merge!({:source => options[:promotion]}) if options[:promotion]
    attributes.merge!({:credit_type_id => CreditType.find_by_code!(options[:credit]).id}) if options[:credit]
    attributes.merge!({:coupon_id => options[:coupon_id]}) if options[:coupon_id]

    current_payment = payment_class.create!(attributes)
    change_state_of(current_payment)
  end

  def process!
    payment.cart_id = cart_service.cart.id
    payment.total_paid = cart_service.total(payment)
    payment.user_id = cart_service.cart.user.id
    payment.save!
    log("Saving Payment data on payment ##{payment.try :id}")

    ActiveRecord::Base.transaction do
      total_liquidation = cart_service.cart.total_liquidation_discount
      total_promotion = cart_service.cart.total_promotion_discount
      billet_discount = cart_service.total_discount_by_type(:billet_discount, payment)
      facebook_discount = cart_service.total_discount_by_type(:facebook_discount, payment)
      total_gift = cart_service.total_discount_by_type(:gift)
      total_coupon = cart_service.total_discount_by_type(:coupon)
      total_credits = cart_service.total_discount_by_type(:credits_by_loyalty_program)
      total_credits_invite = cart_service.total_discount_by_type(:credits_by_invite)
      total_credits_redeem = cart_service.total_discount_by_type(:credits_by_redeem)

      log("Send to Gateway: #{@gateway_strategy.class}")
      payment = @gateway_strategy.send_to_gateway
      log("Returned from Send to Gateway: #{payment.inspect}")

      if @gateway_strategy.payment_successful?
        tracking_order = payment.user.add_event(EventType::TRACKING, @tracking_params) if @tracking_params
        order = cart_service.generate_order!(payment.gateway, tracking_order, payment)
        log("Order generated: #{order.inspect}")
        payment.order = order
        payment.calculate_percentage!
        payment.deliver! if [Debit, CreditCard].include?(payment.class)
        payment.save!

        order.line_items.each do |item|
          variant = Variant.lock("LOCK IN SHARE MODE").find(item.variant.id)
          variant.decrement!(:inventory, item.quantity)
        end

        coupon_opts = cart_service.cart.coupon.nil? ? {} : {:coupon_id => cart_service.cart.coupon.id}

        create_payment_for(facebook_discount, FacebookShareDiscountPayment)
        create_payment_for(total_liquidation, OlookletPayment)
        create_payment_for(billet_discount, BilletDiscountPayment)
        create_payment_for(total_gift, GiftPayment)
        create_payment_for(total_coupon, CouponPayment, coupon_opts)
        create_payment_for(total_promotion, PromotionPayment, {promotion: cart_service.cart.items.first.cart_item_adjustment.source})
        create_payment_for(total_credits, CreditPayment, {:credit => :loyalty_program} )
        create_payment_for(total_credits_invite, CreditPayment, {:credit => :invite} )
        create_payment_for(total_credits_redeem, CreditPayment, {:credit => :redeem} )

        payment.schedule_cancellation if [Debit, Billet].include?(payment.class)

        log("Respond with_success!")
        respond_with_success
      else
        log("Respond with_failure!")
        respond_with_failure
      end
    end

    rescue Exception => error
      ErrorNotifier.send_notifier(@gateway_strategy.class, error, payment)
      respond_with_failure
  end

  private

  def change_state_of(current_payment)
    current_payment.calculate_percentage!
    current_payment.deliver!
    current_payment.authorize!
  end

  def respond_with_failure
    OpenStruct.new(:status => Payment::FAILURE_STATUS, :payment => nil, :error_code => @gateway_strategy.return_code)
  end

  def respond_with_success
    OpenStruct.new(:status => Payment::SUCCESSFUL_STATUS, :payment => payment)
  end

  def log(message, level = :info)
    Rails.logger.send(level, message)
  end
end

