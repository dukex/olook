# -*- encoding : utf-8 -*-
class ShowroomPresenter < BasePresenter

  MORNING   = (0..11)
  AFTERNOON = (12..18)
  EVENING   = (19..23)

  def render_identification friends
    if member.has_facebook? && friends.any?
      h.render :partial => "showroom_facebook_connected", :locals => {:showroom_presenter => self}
    else
      h.render :partial => "showroom_facebook_connect", :locals => {:showroom_presenter => self}
    end
  end

  def collection_name
   Collection.active.try(:name) || I18n.l(Date.today, :format => '%B')
  end

  def display_products(asked_range, category, collection = Collection.active)
    product_finder_service = ProductFinderService.new member
    products = product_finder_service.products_from_all_profiles(:category => category, :collection => collection, description: member && category == Category::SHOE ? member.shoes_size.to_s : nil, not_allow_sold_out_products: true)

    range = parse_range(asked_range, products)

    output = ''
    (products[range] || []).each do |product|
      if product.liquidation?
        output << h.render("shared/promotion_product_item", :liquidation_product => LiquidationProductService.liquidation_product(product))
      else
        output << h.render("shared/showroom_product_item", :showroom_presenter => self, :product => product)
      end
    end
    h.raw output
  end

  def display_shoes(asked_range)
    display_products(asked_range, Category::SHOE)
  end

  def display_bags(asked_range)
    display_products(asked_range, Category::BAG)
  end

  def display_accessories(asked_range)
    display_products(asked_range, Category::ACCESSORY)
  end

  def welcome_message(time = Time.now.hour)
    case
      when MORNING.cover?(time)   then "Bom dia, #{member.first_name}!"
      when AFTERNOON.cover?(time) then "Boa tarde, #{member.first_name}!"
      when EVENING.cover?(time)   then "Boa noite, #{member.first_name}!"
    end
  end

  def facebook_avatar
    # Visit https://developers.facebook.com/docs/reference/api/ for more info
    h.image_tag "https://graph.facebook.com/#{member.uid}/picture?type=large", :class => 'avatar'
  end

private
  def parse_range(asked_range, array)
    if asked_range.is_a? Range
      start_range = asked_range.first
      end_range = asked_range.last
    else
      start_range = asked_range
      end_range = start_range + 100000
    end
    end_range = (array.length-1) if end_range > (array.length-1)
    (start_range..end_range)
  end
end
