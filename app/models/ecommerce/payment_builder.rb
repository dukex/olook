# -*- encoding : utf-8 -*-
class PaymentBuilder
  attr_accessor :cart_service, :payment, :delivery_address, :response, :credit_card_number

  def initialize(cart_service, payment)
    @cart_service, @payment = cart_service, payment
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

      send_payment!
      payment.build_response @response
      set_payment_url!

      if payment.gateway_response_status == Payment::SUCCESSFUL_STATUS
        #NAO EH A MESMA COISA !!
        if payment.gateway_transaction_status != Payment::CANCELED_STATUS

          order = cart_service.generate_order!
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
      else
        respond_with_failure
      end
    end

    rescue Exception => error
      #binding.pry
      error_message = "Moip Request #{error.message} - Order Number #{payment.try(:order).try(:number)} - Payment Expiration #{payment.payment_expiration_date}"
      log(error_message)
      NewRelic::Agent.add_custom_parameters({:error_msg => error_message})
      Airbrake.notify(
        :error_class   => "Moip Request",
        :error_message => error_message
      )

      respond_with_failure
  end

  def set_payment_url!
    payment.url = payment_url
    payment.save!
    payment
  end

  def send_payment!
    @response = MoIP::Client.checkout(payment_data)
  end

  def payment_url
    MoIP::Client.moip_page(response["Token"])
  end

  def payer
    delivery_address = Address.find_by_id!(cart_service.freight[:address_id])
    data = {
      :nome => cart_service.cart.user.name,
      :email => cart_service.cart.user.email,
      :identidade => payment.user_identification,
      :logradouro => delivery_address.street,
      :complemento => delivery_address.complement,
      :numero => delivery_address.number,
      :bairro => delivery_address.neighborhood,
      :cidade => delivery_address.city,
      :estado => delivery_address.state,
      :pais => delivery_address.country,
      :cep => delivery_address.zip_code,
      :tel_fixo => remove_nine_digits_of_telephone(delivery_address.telephone) || remove_nine_digits_of_telephone(delivery_address.mobile),
      :tel_cel => delivery_address.mobile
    }
    data
  end

  def payment_data
    if payment.is_a? Billet
    data = { :valor => payment.total_paid, :id_proprio => payment.identification_code,
                :forma => payment.to_s, :recebimento => payment.receipt, :pagador => payer,
                :razao=> Payment::REASON, :data_vencimento => billet_expiration_date }
    elsif payment.is_a? CreditCard
      data = { :valor => payment.total_paid, :id_proprio => payment.identification_code, :forma => payment.to_s,
                :instituicao => payment.bank, :numero => credit_card_number,
                :expiracao => payment.expiration_date, :codigo_seguranca => payment.security_code,
                :nome => payment.user_name, :identidade => payment.user_identification,
                :telefone => remove_nine_digits_of_telphone(payment.telephone), :data_nascimento => payment.user_birthday,
                :parcelas => payment.payments, :recebimento => payment.receipt,
                :pagador => payer, :razao => Payment::REASON }
    else
      data = { :valor => payment.total_paid, :id_proprio => payment.identification_code, :forma => payment.to_s,
               :instituicao => payment.bank, :recebimento => payment.receipt, :pagador => payer,
               :razao => Payment::REASON }
    end
    data
  end

  private

  def remove_nine_digits_of_telephone(phone_number)
    return false if phone_number.blank?
    phone_number.gsub!("(11)9","(11)") if phone_number =~ /^\(11\)9\d{4}-\d{4}$/
    phone_number
  end

  def billet_expiration_date
    payment.payment_expiration_date.strftime("%Y-%m-%dT15:00:00.0-03:00")
  end

  def respond_with_failure
    OpenStruct.new(:status => Payment::FAILURE_STATUS, :payment => nil)
  end

  def respond_with_success
    OpenStruct.new(:status => payment.gateway_response_status, :payment => payment)
  end

  def log(message, logger = Rails.logger, level = :error)
    logger.send(level, message)
  end
end
