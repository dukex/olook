# -*- encoding : utf-8 -*-
class SpecificItem < PromotionRule

  def matches?(cart, products)
    (get_product_ids_from(cart.items) & product_ids_list_for(products)).any?
  end

  private

    def get_product_ids_from(cart_items)
      cart_items.map { |item| item.product.id }
    end

    def product_ids_list_for(products)
      products.split(",").map { |id| id.strip.to_i }
    end

end

