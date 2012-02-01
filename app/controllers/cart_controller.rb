# -*- encoding : utf-8 -*-
class CartController < ApplicationController
  layout "checkout"

  respond_to :html, :js
  before_filter :authenticate_user!
  before_filter :load_user
  before_filter :check_early_access
  before_filter :check_product_variant, :only => [:create, :update, :update_quantity_product]
  before_filter :current_order
  before_filter :format_credits_value, :only => [:update_bonus]

  def update_coupon
    code = params[:coupon][:code]
    coupon_manager = CouponManager.new(@order, code)
    response_message = coupon_manager.apply_coupon
    redirect_to cart_path, :notice => response_message
  end

  def remove_coupon
    coupon_manager = CouponManager.new(@order)
    response_message = coupon_manager.remove_coupon
    redirect_to cart_path, :notice => response_message
  end

  def remove_bonus
    if @order.credits > 0
      @order.update_attributes(:credits => nil)
      msg = "Créditos removidos com sucesso"
    else
      msg = "Você não está usando nenhum crédito"
    end
    redirect_to cart_path, :notice => msg
  end

  def update_bonus
    bonus = InviteBonus.calculate(@user)
    credits = params[:credits][:value]
    user_can_use_bonus = bonus >= credits.to_f
    if user_can_use_bonus
      @order.update_attributes(:credits => credits)
      destroy_freight(@order)
      redirect_to cart_path, :notice => "Créditos atualizados com sucesso"
    else
      redirect_to cart_path, :notice => "Você não tem créditos suficientes"
    end
  end

  def show
    @bonus = InviteBonus.calculate(@user, @order)
    @cart = Cart.new(@order)
    @line_items = @order.line_items
    @coupon_code = @order.used_coupon.try(:code)
  end

  def destroy
    @order.destroy
    session[:order] = nil
    redirect_to cart_path, :notice => "Sua sacola está vazia"
  end

  def update
    respond_with do |format|
      if @order.remove_variant(@variant)
        destroy_freight(@order)
        destroy_order_if_the_cart_is_empty(@order)
        format.html do
          redirect_to cart_path, :notice => "Produto removido com sucesso"
        end
        format.js do
          head :ok
        end
      else
        format.js do
          head :not_found
        end
        format.html do
          redirect_to cart_path, :notice => "Este produto não está na sua sacola"
        end
      end
    end
  end

  def update_quantity_product
   destroy_freight(@order) if @order.add_variant(@variant, params[:variant][:quantity])
   redirect_to(cart_path, :notice => "Quantidade atualizada")
  end

  def create
    if @order.add_variant(@variant)
      destroy_freight(@order)
      redirect_to(cart_path, :notice => "Produto adicionado com sucesso")
    else
      redirect_to(:back, :notice => "Produto esgotado")
    end
  end

  private

  def clear_gifts_in_the_order(order)
    order.reload
    order.clear_gift_in_line_items
  end

  def destroy_freight(order)
    order.freight.destroy if order.freight
  end

  def destroy_order_if_the_cart_is_empty(order)
    if order.reload.line_items.empty?
      order.destroy
      session[:order] = nil
    end
  end

  def format_credits_value
    params[:credits][:value].gsub!(",",".")
  end

  def check_product_variant
    variant_id = params[:variant][:id] if params[:variant]
    @variant = Variant.find_by_id(variant_id)
    redirect_to(:back, :notice => "Produto não disponível para esta quantidade ou inexistente") unless @variant.try(:available_for_quantity?)
  end

  def current_order
    order_id = (session[:order] ||= @user.orders.create.id)
    @order = @user.orders.find(order_id)
  end

  def load_user
    @user = current_user
  end
end

