# -*- encoding : utf-8 -*-
module ApplicationHelper

  def underscore_case(string)
    string.parameterize.gsub('-', '_')
  end

  def stylesheet_application
    stylesheet_link_tag  "application"
  end

  def is_current?(controller_name, action_name='index')
    'selected' if controller_name == params[:controller] and action_name == params[:action]
  end

  def selected_if_current(controller_action)
    controller_action.each do |item|
      subs = item.split("#")
      category = subs[2]
      return 'selected' if (subs[0] == params[:controller]) && (subs[1] == params[:action]) && (category==nil || (category.to_s == params[:category]))
    end
    return nil
  end

  def present(presenter_class, objects)
    klass ||= "#{presenter_class}Presenter".constantize
    presenter = klass.new(self, objects)
    yield presenter if block_given?
    presenter
  end

  def cart_total(cart)
    content_tag(:span,"(#{content_tag(:span, "#{pluralize(cart.try(:items_total).to_i, 'item', 'itens')}", :id => "cart_items", :class =>"js-minicart_header_items")})".html_safe)
  end

  def discount_percentage(value)
    if value > 0
      "(#{number_to_percentage(value, :precision => 0)})"
    end
  end

  def track_pageview(virtual_url)
    "_gaq.push(['_trackPageview', '#{virtual_url}']);"
  end


  def track_event(*args)
    options = args.last.is_a?(Hash) ? args.last : {}
    category = args[0]
    raise ArgumentError.new('You should pass "category" first argument') unless category
    action = args[1]
    raise ArgumentError.new('You should pass "action" second argument') unless action
    item = args[2] || ''
    no_interactive = !!options[:no_interactive]

    if no_interactive
      "_gaq.push(['_trackEvent', '#{category}', '#{action}', '#{item}', , true]);"
    else
      "_gaq.push(['_trackEvent', '#{category}', '#{action}', '#{item}']);"
    end
  end

  def track_add_to_cart_event(product_id = '')
    track_event("Shopping", "AddToCart#{ga_event_referer}", product_id)
  end

  def track_add_to_cart_valentines_day_event(product_id = '')
    track_event("Shopping", "AddToCartValentinesDay#{ga_event_referer}", product_id)
  end

  def user_avatar(user, type = "large")
    "https://graph.facebook.com/#{user.uid}/picture?type=#{type}"
  end

  def member_type
    if user_signed_in?
      current_user.half_user ? "half#{newsletter_type}" : "quiz#{newsletter_type}"
    else
      "visitor#{newsletter_type}"
    end
  end

  def newsletter_type
    case cookies['newsletterUser']
    when '1'
      '-newsletter'
    when '2'
      '-olookmovel'
    else
      ''
    end
  end

  def quantity_status(product, user)
    if product.sold_out?
      'sold_out'
    elsif user && user.shoes_size && product.shoe?
      quantity = product.quantity(user.shoes_size)
      if quantity == 0
        'sold_out'
      elsif quantity > 0 && quantity < 4
        'stock_down'
      end
    end
  end

  def quantity_status_moments(product, shoe_size)
    if product.sold_out?
      'sold_out'
    elsif shoe_size && product.shoe?
      quantity = product.quantity(shoe_size)
      if quantity == 0
        'sold_out'
      elsif quantity > 0 && quantity < 4
        'stock_down'
      end
    end
  end

  def item_qty_max_option(item)
    if item.cart.user && item.cart.user.reseller && item.cart.user.active
      item.variant.inventory
    else
      [item.variant.inventory, Setting.default_item_quantity.to_i].min
    end
  end

  def item_qty_select(item)
    if item.variant.inventory == 1
      '1 (última peça!)'
    else
      select_tag('quantity', options_for_select((1..item_qty_max_option(item)).to_a, item.quantity), onchange: "changeCartItemQty('#{item.id}');")
    end
  end

  def section_name section
    section_name = Category.t(section)
    section_name.nil? ? 'Coleções' : section_name
  end

  def protocol
    Rails.env.production? ? 'https' : 'http'
  end

  def should_display_footer_bar?
    ["cart/cart", "survey", "landing_pages", "checkout/login"].exclude?(params[:controller]) && params[:ab_t].nil?
  end

  def apply_canonical_link
    unless canonical_link.blank?
      content_tag(:link, nil, href: canonical_link, rel: 'canonical')
    end
  end

  def render_highlighted_products_from campaign
    html = ""
    campaign.product_ids.split('-').map { |pid| campaign.products.find { |p| p.id.to_i == pid.to_i } }.compact.each do |cp|
      html += render :partial => "shared/searched_product_item", :locals => {:product => cp}
    end
    html.html_safe
  end

  def empty_wishlist?
    if current_user
      Wishlist.for(current_user).wished_products.empty?
    else
      true
    end
  end

  def wished_products_count
    if current_user
      Wishlist.for(current_user).size
    else
      0
    end
  end

  def any_wished_product_has_discount?
    if current_user
      wished_products = Wishlist.for(current_user).wished_products
      wished_products.select {|wp| wp.variant.product.promotion?}.any?       
    else
      false
    end
  end

  def has_wished? product_id
    if current_user
      Wishlist.for(current_user).has?(product_id)
    else
      false
    end
  end

  def show_unlogged_home?
    current_user.nil? || current_user.half_user?
  end

  def has_items_in_wishlist?
    current_user && Wishlist.for(current_user).wished_products.any?
  end

  def home_wishlist_images
    wishlist_products = Wishlist.for(current_user).wished_products.last(2)
    product =  wishlist_products.first.variant.product

    wishlist_images = []
    wishlist_images << get_image_for(product, :main)

    if wishlist_products.size > 1
      product = wishlist_products.last.variant.product
      wishlist_images << get_image_for(product, :main)
    else
      wishlist_images << get_image_for(product, :backside)
    end

    wishlist_images.compact
  end

  private

    def get_image_for product, view_type
      main_pic = product.main_picture
      backside_pic = product.backside_picture
      if (view_type == :main && main_pic.present? || view_type == :backside && backside_pic.present?)

        img_url = view_type == :backside ? backside_pic.gsub("catalog","main") : main_pic.image_url(:main)
        {img: img_url, product: product}
      end
    end
 
    def ga_event_referer
      case request.referer
        when /olook.com.br(\/)?$/
          'FromHome'
        when /vitrine/
          'FromVitrine'
        when /tendencias/
          'FromTendencias'
        when /colecoes/
          'FromColecoes'
        when /sapato/
          'FromSapatos'
        when /roupa/
          'FromRoupas'
        when /bolsa/
          'FromBolsas'
        when /acessorio/
          'FromAcessorios'
        when /oculos/
          'FromOculos'
        when /stylists/
          'FromStylists'
        when /presentes/
          'FromPresentes'
        else
          ''
      end
    end
end
