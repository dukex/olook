 # -*- coding: utf-8 -*-
module ProductsHelper
  def variant_classes(variant, shoe_size = nil)
    classes = []
    if !variant.available_for_quantity?
      classes << "unavailable"
    else
      if shoe_size.nil? || shoe_size <= 0
        if current_user && current_user.shoes_size &&
          variant.description == current_user.shoes_size.to_s
            classes << "selected"
        end
      else
        classes << "selected" if variant.description.to_s == shoe_size.to_s
      end
    end
    classes.join(" ")
  end

  def share_description(product)
    if product.category == 1 #shoes
      "Vi o sapato #{product.name} no site da olook e amei! <3 www.olook.com.br/produto/#{product.id}"
    elsif product.category == 2 #purse
      "Vi a bolsa #{product.name} no site da olook e amei! <3 www.olook.com.br/produto/#{product.id}"
    else #accessory
      "Vi o acessório #{product.name} no site da olook e amei! <3 www.olook.com.br/produto/#{product.id}"
    end
  end

  def print_detail_name_for category, detail 

    name = detail.translation_token.downcase

    if name == 'categoria'
      'Modelo'
    elsif name == 'material externo' && category == Category::CLOTH
      'Composição'
    elsif name == 'salto' && category == Category::CLOTH
      'Tamanhos & Medidas'   
    elsif name == 'salto' && (category == Category::BAG || category == Category::ACCESSORY)
      'Tamanho'
    elsif name == 'metal' && category == Category::ACCESSORY
      'Material'
    else
      detail.translation_token
    end

  end

  def print_detail_value detail
    html_sizes = ""
    sizes = detail.description.split(";")
    sizes.each do |size|
      html_sizes << "#{size.chomp}<br>"
    end
    html_sizes.html_safe
  end
end
