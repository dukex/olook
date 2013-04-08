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

  def collection_name(collection = Collection.active)
    collection.try(:name) || I18n.l(Date.today, :format => '%B')
  end

  def display_products(asked_range, category, collection = Collection.active, user=nil, shoes_size=nil)

    product_finder_service = ProductFinderService.new member, admin, collection
    products = product_finder_service.products_from_all_profiles(:category => category,
                                                                 :description => shoes_size,
                                                                 :collection => collection)

    #
    # Andressa asked by a custom behavior for clothes (I hope rip this off as soon as possible)
    #
    if category == Category::CLOTH && member.try(:main_profile)
      main_profile = member.main_profile.alternative_name
      main_profile = ['casual', 'chic', 'sexy', 'moderna'].include?(main_profile) ? main_profile : 'casual'
      products = Set.new(Product.clothes_for_profile(main_profile) + products).to_a
    end

    range = parse_range(asked_range, products)
    output = ''
    (products[range] || []).each do |product|
      # product = change_order_using_inventory(product) if user
      if product.liquidation?
        output << h.render("shared/product_item", :product => LiquidationProductService.liquidation_product(product).product)
      else
        output << h.render("shared/product_item", :showroom_presenter => self, :product => product)
      end
    end
    h.raw output
  end

  def display_clothes(asked_range, collection = Collection.active, user=nil)
    display_products(asked_range, Category::CLOTH, collection, user)
  end

  def display_shoes(asked_range, collection = Collection.active, user=nil)
    display_products(asked_range, Category::SHOE, collection, user, user.try(:shoes_size))
  end

  def display_bags(asked_range, collection = Collection.active, user=nil)
    display_products(asked_range, Category::BAG, collection, user)
  end

  def display_accessories(asked_range, collection = Collection.active, user=nil)
    display_products(asked_range, Category::ACCESSORY, collection, user)
  end

  def facebook_avatar
    # Visit https://developers.facebook.com/docs/reference/api/ for more info
    h.image_tag "https://graph.facebook.com/#{member.uid}/picture?type=large", :class => 'avatar'
  end

  def change_order_using_inventory(product)
    array = []
    array << product
    array << product.colors
    array = array.flatten.compact
    array = array.sort{|x,y| y.inventory <=> x.inventory}
    product = array.first
    product
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
