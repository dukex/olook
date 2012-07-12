# -*- encoding : utf-8 -*-
class CartController < ApplicationController
  layout "checkout"

  respond_to :html, :js

  def show
    @bonus = 0
    if @user
      @bonus = @user.current_credit - @cart.credits
    end
  end

  def destroy
    @cart.destroy
    session[:cart_id] = nil
    redirect_to cart_path, notice: "Sua sacola está vazia"
  end

  def update
    variant_id = params[:variant][:id] if params[:variant]

    respond_with do |format|
      if @cart.remove_item(Variant.find_by_id(variant_id))
        format.html { redirect_to cart_path, notice: "Produto removido com sucesso" }
        format.js { head :ok }
      else
        format.js { head :not_found }
        format.html { redirect_to cart_path, notice: "Este produto não está na sua sacola" }
      end
    end
  end

  def create
    variant_id = params[:variant][:id] if params[:variant]
    variant = Variant.find_by_id(variant_id)
    
    if variant.nil?
      respond_with do |format|
        format.js { render :error, :locals => { :notice => "Por favor, selecione os atributos do produto." }}
        format.html { redirect_to(:back, :notice => "Produto não disponível para esta quantidade ou inexistente") }
      end
    else
      if @cart.add_item(variant)
        respond_with do |format|
          format.html { redirect_to(cart_path, notice: "Produto adicionado com sucesso") }
        end
      else
        respond_with(@cart) do |format|
          notice_response = @cart.has_gift_items? ? "Produtos de presente não podem ser comprados com produtos da vitrine" : "Produto esgotado"
          format.js { render :error, locals: { notice: notice_response } }
          format.html { redirect_to(cart_path, notice: notice_response) }
        end
      end
    end
  end
  
  def update_gift_wrap
    session[:gift_wrap] = params[:gift][:gift_wrap] if params[:gift] && params[:gift][:gift_wrap]
    render :json => true
  end
  
  def update_coupon
    code = params[:coupon][:code]
    coupon = Coupon.find_by_code(code)
    
    response_message = if coupon.try(:expired?)
      "Cupom expirado. Informe outro por favor"
    elsif coupon.try(:available?)
      session[:session_coupon] = coupon
      "Cupom atualizado com sucesso"
    else
      session[:session_coupon] = nil
      "Cupom inválido"
    end
    
    redirect_to cart_path, :notice => response_message
  end

  def remove_coupon
    response_message = session[:session_coupon] ? "Cupom removido com sucesso" : "Você não está usando cupom"
    session[:session_coupon] = nil
    redirect_to cart_path, :notice => response_message
  end

  def remove_credits
    if @cart.credits > 0
      session[:credits] = nil
      msg = "Créditos removidos com sucesso"
    else
      msg = "Você não está usando nenhum crédito"
    end
    redirect_to cart_path, :notice => msg
  end

  def update_credits
    params[:credits][:value].gsub!(",",".")
    
    credits = BigDecimal.new(params[:credits][:value].to_s)
    if @user.current_credit >= credits && credits > 0
      @cart.credits = credits
      session[:credits] = @cart.credits_discount
      if credits > session[:credits]
        redirect_to cart_path, :notice => "Você tentou utilizar mais que o permitido para esta compra , utilizamos o máximo permitido."
      else
        redirect_to cart_path, :notice => "Créditos atualizados com sucesso"
      end
    else
      redirect_to cart_path, :notice => "Você não tem créditos suficientes"
    end
  end
end

