# -*- encoding : utf-8 -*-
module CartHelper

  # TODO USER AND CART AS PARAMETER AND NOT AS INSTANCE VARIABLE, IT'S NOT MY FAULT
  def print_credit_message
    "(disponível apenas em pedidos acima de R$ 100 e sem desconto)" unless @cart_service.allow_credit_payment?
  end

  def total_user_credits
    return 0.0 if @user.nil?
    return @user.current_credit if @cart_service.allow_credit_payment?
    @user.user_credits_for(:redeem).total
  end

  def promotion_discount(item)
    percent = ( 1 - ( item.retail_price / item.price )  ) * 100.0
    percent == 100 ? "Grátis" : number_to_percentage(percent, :precision => 0)
  end

  def remaining_items cart, promotion
    cart_items = cart.items.select { |item| !item.is_suggested_product? }
    promotion.param.to_i - cart_items.size % promotion.param.to_i
  end

  def free_item_promotion_is_active?
    false
  end

  def has_discount?(item)
    item.discount_service.has_any_discount?
  end

  def show_checkout_banner?
    #promotion = Promotion.active_and_not_expired(Date.today).order(:updated_at).last
    #return false if promotion.nil?
    #! promotion.matches?(@cart)
    return Setting.show_checkout_banner
  end

  def loyalty_credits_treshold
    100
  end
end
