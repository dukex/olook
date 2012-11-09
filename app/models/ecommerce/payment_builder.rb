# -*- encoding : utf-8 -*-
class PaymentBuilder
  attr_accessor :cart_service, :payment, :delivery_address, :response, :gateway_strategy

  def initialize(cart_service, payment, gateway_strategy)
    @cart_service, @payment, @gateway_strategy = cart_service, payment, gateway_strategy
  end

  def process!
    payment.cart_id = @cart_service.cart.id
    payment.total_paid = @cart_service.total
    payment.user_id = cart_service.cart.user.id
    payment.save!

    ActiveRecord::Base.transaction do
      total_olooklet = cart_service.total_discount_by_type(:olooklet)
      total_gift = cart_service.total_discount_by_type(:gift)
      total_coupon = cart_service.total_discount_by_type(:coupon)
      total_promotion = cart_service.total_discount_by_type(:promotion)
      total_credits = cart_service.total_discount_by_type(:credits_by_loyalty_program)
      total_credits_invite = cart_service.total_discount_by_type(:credits_by_invite)
      total_credits_redeem = cart_service.total_discount_by_type(:credits_by_redeem)

      payment = @gateway_strategy.send_to_gateway

      if @gateway_strategy.payment_successful?
        order = cart_service.generate_order!(payment.gateway)
        payment.order = order
        payment.calculate_percentage!
        payment.deliver! if payment.kind_of?(CreditCard)
        payment.deliver! if payment.kind_of?(Debit)
        payment.save!

        order.line_items.each do |item|
          variant = Variant.lock("LOCK IN SHARE MODE").find(item.variant.id)
          variant.decrement!(:inventory, item.quantity)
        end

        if total_olooklet > 0
          olooklet_payment = OlookletPayment.create!(
            :total_paid => total_olooklet,
            :order => order,
            :user_id => payment.user_id,
            :cart_id => @cart_service.cart.id)
          olooklet_payment.calculate_percentage!
          olooklet_payment.deliver!
          olooklet_payment.authorize!
        end

        if total_gift > 0
          gift_payment = GiftPayment.create!(
            :total_paid => total_gift,
            :order => order,
            :user_id => payment.user_id,
            :cart_id => @cart_service.cart.id)
          gift_payment.calculate_percentage!
          gift_payment.deliver!
          gift_payment.authorize!
        end


        if total_coupon > 0
          coupon_payment = CouponPayment.create!(
            :total_paid => total_coupon,
            :coupon_id => cart_service.coupon.id,
            :order => order,
            :user_id => payment.user_id,
            :cart_id => @cart_service.cart.id)
          coupon_payment.calculate_percentage!
          coupon_payment.deliver!
          coupon_payment.authorize!
        end


        if total_promotion > 0
          promotion_payment = PromotionPayment.create!(
            :total_paid => total_promotion,
            :promotion_id => cart_service.promotion.id,
            :order => order,
            :user_id => payment.user_id,
            :discount_percent => cart_service.promotion.discount_percent,
            :cart_id => @cart_service.cart.id)
          promotion_payment.calculate_percentage!
          promotion_payment.deliver!
          promotion_payment.authorize!
        end

        if total_credits > 0
          credit_payment = CreditPayment.create!(
            :credit_type_id => CreditType.find_by_code!(:loyalty_program).id,
            :total_paid => total_credits,
            :order => order,
            :user_id => payment.user_id,
            :cart_id => @cart_service.cart.id)
          credit_payment.calculate_percentage!
          credit_payment.deliver!
          credit_payment.authorize!
        end

        if total_credits_invite > 0
          credit_payment_invite = CreditPayment.create!(
            :credit_type_id => CreditType.find_by_code!(:invite).id,
            :total_paid => total_credits_invite,
            :order => order,
            :user_id => payment.user_id,
            :cart_id => @cart_service.cart.id)
          credit_payment_invite.calculate_percentage!
          credit_payment_invite.deliver!
          credit_payment_invite.authorize!
        end

        if total_credits_redeem > 0
          credit_payment_redeem = CreditPayment.create!(
            :credit_type_id => CreditType.find_by_code!(:redeem).id,
            :total_paid => total_credits_redeem,
            :order => order,
            :user_id => payment.user_id,
            :cart_id => @cart_service.cart.id)
          credit_payment_redeem.calculate_percentage!
          credit_payment_redeem.deliver!
          credit_payment_redeem.authorize!
        end
        respond_with_success
      else
        respond_with_failure
      end
    end

    rescue Exception => error
      ErrorNotifier.send(@gateway_strategy.class, error, payment)
      respond_with_failure
  end

  private

  def respond_with_failure
    OpenStruct.new(:status => Payment::FAILURE_STATUS, :payment => nil)
  end

  def respond_with_success
    OpenStruct.new(:status => Payment::SUCCESSFUL_STATUS, :payment => payment)
  end

  def log(message, logger = Rails.logger, level = :error)
    logger.send(level, message)
  end
end
