CACHE_KEYS = {
  product_item_partial_shoe: { key: '_product_item:%s|shoe_size:%s', expire: 30*60 },
  product_item_partial: { key: '_product_item:%s', expire: 30*60 },
  lite_product_item_partial_shoe: { key: '_lite_product_item:%s|shoe_size:%s', expire: 30*60 },
  lite_product_item_partial: { key: '_lite_product_item:%s', expire: 30*60 },
  product_picture_image_catalog: { key: 'C_I_P_%sd%s', expire: 24*3600 },
  product_colors: { key: "p:colors:%s:%s", expire: 30*60 },
  product_clothes_for_profile: { key: "SR:%s", expire: 10*60 },
  product_fetch_all_featured_products_of: { key: "featured_products_%s", expire: 10*60 },
  detail_color: { key: "detail:colors:%s", expire: 30*60 }
}
