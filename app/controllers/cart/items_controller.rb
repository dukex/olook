# -*- encoding : utf-8 -*-
class Cart::ItemsController < ApplicationController
  respond_to :js, :json
  before_filter :ensure_params!
  prepend_before_filter :create_cart

  def create
    ensure_a_variant_is_found!
    add_item_or_show_errors
  end

  def update
    @item = @cart.items.find(params[:id])

    if @item.update_attribute(:quantity, params[:quantity])
      @cart.items.reload
      @cart_calculator = CartProfit::CartCalculator.new(@cart)
      @freebie = Freebie.new(subtotal: @cart.sub_total, cart_id: @cart.id)
      @cart.uncheck_credit_usage_if_unallowed
      
      respond_with { |format| format.js {  } }
    else
      render :error, :locals => { :notice => "Houve um problema ao atualizar a quantidade do item do cart" }
    end
  end

  def destroy
    @item = @cart.items.find_by_id(params[:id])

    if !@item || @item.destroy
      @cart.items.reload
      @cart_calculator = CartProfit::CartCalculator.new(@cart)
      @freebie = Freebie.new(subtotal: @cart.sub_total, cart_id: @cart.id)
      respond_with { |format| format.js { } }
    else
      render :error, :locals => { :notice => "Houve um problema ao deletar o item do cart" }
    end
  end

  private

  def add_item_or_show_errors
    @cart ||= create_cart
    unless @item = @cart.add_item(@variant, variant_qty)
      respond_with(@cart) do |format|
        notice_response = @cart.has_gift_items? ? "Produtos de presente não podem ser comprados com produtos da vitrine" : "Produto esgotado"

        render_error_on_create(notice_response,format)
        format.html { render text: notice_response }
      end
    else
      respond_with(@cart) do |format|
        format.json{ render json: {}, status: :ok }
        format.html{ redirect_to cart_path }
      end
    end
  end

  def ensure_a_variant_is_found!
    respond_with do |format|
      render_error_on_create("Por favor, selecione o tamanho do produto.", format)
    end unless adding_a_cart_item? && a_variant_is_found
  end

  def a_variant_is_found
    @variant = Variant.find_by_id(variant_id)
  end

  def ensure_params!
    if adding_a_cart_item?
      respond_with do |format|
        render_error_on_create("Por favor, selecione o tamanho do produto.", format)
      end unless (params[:variant] && params[:variant][:id])
    elsif updating_a_cart_item_qty?
      respond_with do |format|
        render_error_on_create("Não foram enviados os parâmetros para atualizar a quantidade do item",format)
      end unless (params[:id] && params[:quantity])
    else
      #DELETE to destroy
      respond_with do |format|
        render_error_on_create("Houve um problema ao deletar o item do carrinho", format)
      end unless (params[:id] && !params[:id].empty?)
    end
  end

  def adding_a_cart_item?
    request.method == 'POST' && params[:action] == 'create'
  end

  def updating_a_cart_item_qty?
    request.method == 'PUT'
  end

  def removing_a_cart_item?
    request.method == 'DELETE'
  end

  def variant_id
    params[:variant][:id] if params[:variant]
  end

  def variant_qty
    params[:variant][:quantity]
  end

  private

    def render_error_on_create(notice_response, format)
      format.js { render :error, locals: { notice: notice_response } }
      format.json{ render json: {notice: notice_response}, status: :unprocessable_entity }
    end

end
