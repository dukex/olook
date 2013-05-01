# -*- encoding : utf-8 -*
class MenuPresenter < BasePresenter

  def render_item label, path, css_klass, hightlight_when
   #+(css_klass == "stylist" ? h.image_tag("home/only_balaozinho.png") : "")
    h.content_tag(:li, h.link_to(label, path, :class => h.selected_if_current(hightlight_when)),:class => css_klass)
  end

  def render_item_with_label label, path, css_klass, hightlight_when
    h.content_tag :li, :class => css_klass do
      h.content_tag(:span, "Novo", :class => "label") +
      h.link_to(label, path, :class => h.selected_if_current(hightlight_when), :target => "_blank")
    end
  end

  def render_menu
    if user
      user.half_user ? render_half_user_menu : render_default_menu
    else
      render_offline_menu
    end
  end

  def render_offline_menu
    [showroom_offline, stylist, collection_themes, categories, gift, liquidation].join.html_safe
  end

  def render_default_menu
    [showroom, stylist, collection_themes, categories, gift, liquidation].join.html_safe
  end

  def render_half_user_menu
    if user.female?
      render_woman_half_user_menu
    else
      render_man_half_user_menu
    end
  end

  def render_woman_half_user_menu
    render_default_menu
  end

  def render_man_half_user_menu
    [lookbooks, collection_themes, my_friends, stylist, liquidation, blog].join.html_safe
  end

  private
  def showroom_offline
    render_item("Minha Vitrine", h.root_path, "showroom", ["home#index"])
  end

  def showroom
    render_item("Minha Vitrine", h.member_showroom_path, "showroom", ["members#showroom"])
  end

  def lookbooks
    render_item("Tendências", h.lookbooks_path, "lookbooks", ["lookbooks#index","lookbooks#show"])
  end

  def stylist
    render_item("Stylist News", "/stylist-news", "stylist", ['stylists#helena_linhares'])
  end

  def my_friends
    render_item("Minhas amigas", h.facebook_connect_path, "my_friends", ['friends#facebook_connect','friends#home','friends#showroom'])
  end

  def invite
    render_item("Convidar amigas", h.member_invite_path, "invite", ["members#invite"])
  end

  def collection_themes
    render_item("Coleções", h.collection_themes_path, "collection_themes", ["collection_themes#index"])
  end

  def categories
    [clothes, shoes, bags, accessories]
  end

  def clothes
    render_item("Roupas", h.clothes_path, "categories", ["moments#clothes"])
  end

  def shoes
    render_item("Sapatos", h.shoes_path, "categories", ["moments#show#1"])
  end

  def bags
    render_item("Bolsas", h.bags_path, "categories", ["moments#show#2"])
  end

  def accessories
    render_item("Acessórios", h.accessories_path, "categories", ["moments#show#3"])
  end

  def glasses
    render_item("Óculos", h.glasses_path, "categories", ["moments#glasses"])
  end

  def gift
    render_item("Presentes", h.gift_root_path, "gift",
     [
      "gift/home#index",
      "gift/occasions#new",
      "gift/occasions#new_with_data",
      "gift/survey#new",
      "gift/recipients#edit",
      "gift/suggestions#index"
     ]
    )
  end

  def liquidation
    render_item(h.current_liquidation.name, h.liquidations_path(h.current_liquidation.id), "liquidation", ["liquidations#show"]) if h.show_current_liquidation?
  end

  def blog
    h.content_tag :li, h.link_to("Blog", "http://blog.olook.com.br", :target => "_blank"), :class => "blog"
  end
end

