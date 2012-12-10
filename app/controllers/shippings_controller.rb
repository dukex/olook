# -*- encoding : utf-8 -*-
class ShippingsController < ApplicationController
  DEFAULT_VALUE = 50.0
  respond_to :json

  def show
    zip_code = params[:id]
    freight = FreightCalculator.freight_for_zip zip_code, DEFAULT_VALUE

    if freight.empty?
      render :status => :not_found 
    else
      @days_to_deliver = freight[:delivery_time]
      # render :show , :format => :json
    end
  end


end