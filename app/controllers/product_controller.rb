# -*- encoding : utf-8 -*-
class ProductController < ApplicationController
  respond_to :html
  before_filter :authenticate_user!, :except => [:show, :create_offline_session]
  before_filter :load_user
  before_filter :check_product_variant, :only => [:add_to_cart]
  before_filter :load_order

  def show
    @facebook_app_id = FACEBOOK_CONFIG["app_id"]
    @url = request.protocol + request.host
    @product = Product.only_visible.find(params[:id])
    @variants = @product.variants
    respond_to :html, :js
  end

  def create_offline_session
    @offline_variant_session = (session[:offline_variant] = params[:variant])
    @offline_first_access_session = session[:offline_first_access] = true
    respond_to do |format|
      format.json { render :json => @offline_variant_session }
    end
  end
end

