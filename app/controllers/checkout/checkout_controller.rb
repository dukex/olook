# -*- encoding : utf-8 -*-
class Checkout::CheckoutController < Checkout::BaseController

  before_filter :authenticate_user!
  before_filter :check_order
  before_filter :check_cpf

  def new
    @addresses = @user.addresses
    @report  = CreditReportService.new(@user)
    @checkout = Checkout.new
  end

  def create
    address = shipping_address(params)
    payment = create_payment(address)
    payment_method = params[:checkout][:payment_method]

    payment_valid = payment && payment.valid?
    address_valid = address && address.valid?
    unless payment_valid & address_valid
      display_form(address, payment, payment_method)
      return
    end

    address.save
    @cart_service.cart.address = address

    sender_strategy = PaymentService.create_sender_strategy(@cart_service, payment)
    payment_builder = PaymentBuilder.new({ :cart_service => @cart_service, :payment => payment, :gateway_strategy => sender_strategy, :tracking_params => session[:order_tracking_params] } )
    
    response = payment_builder.process!

    if response.status == Payment::SUCCESSFUL_STATUS
      clean_cart!
      return redirect_to(order_show_path(:number => response.payment.order.number))
    else
      @addresses = @user.addresses
      display_form(address, payment, payment_method, error_message_for(response, payment))
      return
    end
  end

  private

    def error_message_for response, payment
      return "Identificamos um problema com a forma de pagamento escolhida." unless payment.is_a? CreditCard 

      if response.error_code == "BP07"
        error_message = "Tempo de retorno da operadora de cartão excedido.<br>Tente novamente ou escolha outra forma de pagamento."
      else
        error_message = "Identificamos um problema com o cartão.<br>Confira os dados ou tente outra forma de pagamento."
      end
      error_message  
    end

    def shipping_address(params)
      if using_address_form?
        populate_shipping_address
      else
        Address.find_by_id(params[:address][:id]) if params[:address]
      end
    end

    def populate_shipping_address
      params[:checkout][:address][:country] = 'BRA'
      address = params[:checkout][:address][:id].blank? ? @user.addresses.build() : @user.addresses.find(params[:checkout][:address][:id])
      params[:checkout][:address].delete(:id)
      address.assign_attributes(params[:checkout][:address])
      address
    end

    def create_payment(address)
      params[:checkout][:payment][:receipt] = Payment::RECEIPT
      params[:checkout][:payment][:telephone] = address.telephone if address

      payment = case params[:checkout][:payment_method]
      when "billet"
        Billet.new(params[:checkout][:payment])
      when "debit"
        Debit.new(params[:checkout][:payment])
      when "credit_card"
        CreditCard.new(params[:checkout][:payment] )
      else
        nil
      end
    end

    def display_form(address, payment, payment_method, error_message = nil)
      @report  = CreditReportService.new(@user)
      @checkout = Checkout.new(address: address, payment: payment, payment_method: payment_method)
      if error_message
        @checkout.errors.add(:payment_base, error_message)
        # TODO => Move these lines to Payment class
        @checkout.payment.errors.add(:credit_card_number)
        @checkout.payment.errors.add(:expiration_date)
        @checkout.payment.errors.add(:security_code)
        payment.credit_card_number = ""
        payment.expiration_date = ""
        payment.security_code = ""
      end

      unless using_address_form?
        @addresses = @user.addresses
        unless address
          @checkout.address = Address.new
          @checkout.errors.add(:address_base, "Escolha um endereço!")
        end
      end

      unless payment
        @checkout.errors.add(:payment_base, "Como você pretende pagar? Escolha uma das opções")
      end

      render :new
    end

    def using_address_form?
      !params[:checkout][:address].nil?
    end

end
