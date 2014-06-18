# -*- encoding : utf-8 -*-
class SpecificItem < PromotionRule

  def name
    'Colocar na sacola os itens de IDs...'
  end

  def need_param
    true
  end

  def matches?(cart, products)
    return false unless cart
    (get_product_ids_from(cart.items) & product_ids_list_for(products)).size == 1
  end

  private

    def get_product_ids_from(cart_items)
      cart_items.map { |item| item.product.id }
    end

    def product_ids_list_for(products)
      products.split(/\D/).map { |id| id.strip.to_i }.select { |id| !id.nil? && id != '' }
    end

end

