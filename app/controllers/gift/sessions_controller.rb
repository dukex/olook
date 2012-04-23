# -*- encoding : utf-8 -*-
class Gift::SessionsController < Devise::SessionsController
  after_filter :create_sign_in_event, :only => :create
  before_filter :create_sign_out_event, :only => :destroy

  protected

  def create_sign_in_event
    if current_user.is_a?(User)
      current_user.add_event(EventType::SIGNIN)
    end
  end

  def create_sign_out_event
    if current_user.is_a?(User)
      current_user.add_event(EventType::SIGNOUT)
    end
  end

  private

  def after_sign_in_path_for(resource_or_scope)
    #"products"=>{"0"=>"2078",
    #"1"=>"1865",
    #"2"=>"2761"}
    add_products_to_gift_cart_cart_path
  end
end

