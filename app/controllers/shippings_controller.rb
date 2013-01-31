# -*- encoding : utf-8 -*-
class ShippingsController < ApplicationController
  DEFAULT_VALUE = 50.0
  respond_to :json, :js

  def show
    zip_code = params[:id]

    freight =  FreightCalculator.freight_for_zip(zip_code, @cart_service.subtotal > 0 ? @cart_service.subtotal : DEFAULT_VALUE)

    if freight.empty?
      render :status => :not_found 
    else
      @days_to_deliver = freight[:delivery_time]
      @freight_price = freight[:price] 
      # render :show , :format => :json
    end
  end


end