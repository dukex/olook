# -*- encoding : utf-8 -*-
class Checkout::PaymentsController < ApplicationController
  layout "checkout"

  respond_to :html
  before_filter :authenticate_user!, :only => [:index]
  before_filter :check_freight, :only => [:index]
  protect_from_forgery :except => :create

  def index
  end

  def show
    @payment = @user.payments.find(params[:id])
    # @cart = CartPresenter.new(@payment.order)
  end

  def create
    order = Order.find_by_identification_code(params["id_transacao"])
    MoipCallback.create(:order_id => order.try(:id),
                        :cod_moip => params["cod_moip"],
                        :tipo_pagamento => params["tipo_pagamento"],
                        :status_pagamento => params["status_pagamento"],
                        :id_transacao => params["id_transacao"])
    if order
      if update_order(order)
        render :nothing => true, :status => 200
      else
        msg = "Erro ao mudar status do pagamento"
        NewRelic::Agent.add_custom_parameters({:msg => msg, :params => params})
        Airbrake.notify(:error_class => "Payment", :error_message => msg, :parameters => params)
        logger.error(msg)
        logger.error(params)
        render :nothing => true, :status => 500
      end
    else
      msg = "Order não encontrada"
      NewRelic::Agent.add_custom_parameters({:msg => msg, :params => params})
      Airbrake.notify(:error_class => "Order", :error_message => msg, :parameters => params)
      logger.error(msg)
      logger.error(params)
      render :nothing => true, :status => 500
    end
  end

  private

  def update_order(order)
    if order.payment
      order.payment.update_attributes(:gateway_code   => params["cod_moip"],
                                      :gateway_type   => params["tipo_pagamento"],
                                      :gateway_status => params["status_pagamento"])

      canceled_status = Payment::STATUS["5"].to_s

      if params["status_pagamento"] == canceled_status
        cancellation_reason_message = order.payment_response.message if order.payment_response
        order.create_cancellation_reason(:source => Order::CANCELLATION_SOURCE[:moip], :message => cancellation_reason_message)
      end

      order.payment.set_state(params["status_pagamento"])
    end
  end
  
  def check_freight
    redirect_to addresses_path, :notice => "Escolha seu endereço" if @cart.freight.nil?
  end
end
