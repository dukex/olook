# -*- encoding : utf-8 -*-
class Gift::HomeController < Gift::BaseController
  layout 'gift'

  before_filter :check_facebook_permissions
  before_filter :load_facebook_adapter
  before_filter :load_friends
  rescue_from Koala::Facebook::APIError, :with => :facebook_api_error

  def index
    @profiles_products = fetch_profiles_products
    @suggestion_products = Product.find(12472, 10770, 10675, 11636, 11961)
  end

  def update_birthdays_by_month
    @friends = @facebook_adapter.facebook_friends_with_birthday(params[:month]) if @facebook_adapter
  end

  def current_month
    Time.now.month
  end

  def check_facebook_permissions
    if @user && @user.has_facebook_friends_birthday?
      session[:facebook_scopes] = nil
    else
      session[:facebook_redirect_paths] = "gift"
    end
  end

  def load_facebook_adapter
    if current_user && current_user.has_facebook_friends_birthday?
      @facebook_adapter = FacebookAdapter.new current_user.facebook_token
    end
  end

  def load_friends
    @friends = @facebook_adapter.facebook_friends_with_birthday(current_month) if @facebook_adapter
  end

  private

    def facebook_api_error
      current_user.remove_facebook_permissions!
      respond_to do |format|
        format.html { redirect_to(gift_root_path, :alert => I18n.t("facebook.connect_failure")) }
        format.js { head :error }
      end
    end

    def fetch_profiles_products
      profiles_products = {}
      [:modern, :casual, :chic, :sexy].each do |profile|
        profiles_products[profile] = fetch_product_for_profile profile
      end
      profiles_products
    end

    def fetch_product_for_profile profile
      product_ids_to_find = Setting.send("profile_#{profile}_product_ids").split(",").map{|id| id.to_i}
      Product.find_all_by_id product_ids_to_find
    end

end
