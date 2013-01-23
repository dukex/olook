class Checkout::LoginController < ApplicationController

  layout "checkout"

  before_filter :check_user_logged
  
  def index
    session[:facebook_redirect_paths] = "checkout"
  end

  private

  def check_user_logged
    redirect_to checkout_cart_path if logged_in?
  end

end