# -*- encoding : utf-8 -*-
class LiquidationsController < ApplicationController
  layout "liquidation"
  respond_to :html, :js

  before_filter :verify_if_active, :only => [:show, :index]
  before_filter :load_liquidation_products

  def index
    render :action => :show
  end

  def show
    @teaser_banner = current_liquidation.teaser_banner_url if current_liquidation
    if current_liquidation.resume.nil?
      flash[:notice] = "A liquidação não possui produtos"
      redirect_to member_showroom_path 
    else
      respond_with @liquidation_products
    end
  end

  def update
    respond_with @liquidation_products
  end

  private

  def load_liquidation_products
      liquidation_id = params[:id]
      @liquidation = Liquidation.find(liquidation_id)
      @liquidation_products = LiquidationSearchService.new(params).search_products
  end

  def verify_if_active

    if current_liquidation.nil?
      flash[:notice] = "A liquidação não está ativa"
      redirect_to member_showroom_path
    else
      # To show just the shoes of the user size at the 
      # first time that the liquidations page is rendered
      params[:shoe_sizes] = current_user.shoes_size.to_s if current_user && current_user.shoes_size
      params[:id] = current_liquidation.id
    end
  end
end
