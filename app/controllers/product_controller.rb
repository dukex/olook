# -*- encoding : utf-8 -*-
class ProductController < ApplicationController
  respond_to :html
  before_filter :load_show_product, only: [:show, :spy, :product_valentines_day]


  rescue_from ActiveRecord::RecordNotFound do
    ### to render home partials ###
    @stylist = Product.fetch_products :selection
    render :template => "/errors/404.html.erb", :layout => 'error', :status => 404, :layout => "lite_application"
  end

  def show
  end
  
  def product_valentines_day
    girlfriend = User.find_by_id(ParameterEncoder.decode(params[:encrypted_id]).to_i)
    @user_data = FacebookAdapter.new(girlfriend.facebook_token).retrieve_user_data
    render layout: 'valentines_day'
  end

  def spy
    render layout: 'application'
  end

  def share_by_email
    name_and_emails = params.slice(:name_from, :email_from, :emails_to_deliver)
    @product = Product.find(params[:product_id])
    @product.share_by_email(name_and_emails)
    #redirect_to(:back, notice: "Emails enviados com sucesso!")
  end

  private
  def load_show_product
    @google_path_pixel_information = "Produto"
    @facebook_app_id = FACEBOOK_CONFIG["app_id"]
    @url = request.protocol + request.host

    @product = if current_admin
      Product.find(params[:id])
    else
      p = Product.only_visible.find(params[:id])
      raise ActiveRecord::RecordNotFound unless p.price > 0
      p
    end

    @google_pixel_information = @product
    @chaordic_user = ChaordicInfo.user(current_user,cookies[:ceid])
    @chaordic_product = ChaordicInfo.product @product
    @chaordic_category = @product.category_humanize
    @variants = @product.variants

    @gift = (params[:gift] == "true")
    @only_view = (params[:only_view] == "true")
    @shoe_size = params[:shoe_size].to_i
  end
end
