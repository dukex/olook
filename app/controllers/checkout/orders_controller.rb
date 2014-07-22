# -*- encoding : utf-8 -*-
class Checkout::OrdersController < Checkout::BaseController
  before_filter :authenticate_user!

  def show
    @order = @user.orders.find_by_number!(params[:number])
    @payment = @order.erp_payment
    promotion = @order.payments.where(:type => "PromotionPayment").first.try(:promotion)

    coupon_pm = @order.payments.where(:type => "CouponPayment").first
    coupon = coupon_pm.coupon if coupon_pm
    @chaordic_confirmation = ChaordicInfo.buy_order @order
    @google_path_pixel_information = "purshase"
    @google_pixel_information = @order

    @cart_service_for_order = CartService.new(
      :cart => @order.cart
    )

    @zanpid = request.referer[/.*=([^=]*)/,1] if request.referer =~ /zanpid/
    @criteo = @order.tracking && @order.tracking.utm_source.to_s.match(/criteo.*/) ? 1 : 0

    # teste a/b para cores dos icones na pagina de produto
    finished("advantage_icons")
  end

end
