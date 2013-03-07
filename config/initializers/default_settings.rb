Setting.defaults[:abacos_integrate] = true
Setting.defaults[:abacos_invetory] = true
Setting.defaults[:invite_credits_available] = true
Setting.defaults[:loyalty_program_credits_available] = true
Setting.defaults[:invite_credits_bonus_for_inviter] = "20.00"
Setting.defaults[:invite_credits_bonus_for_invitee] = "10.00"
Setting.defaults[:percentage_on_order] = "0.20"
Setting.defaults[:billet_discount_available] = true
Setting.defaults[:billet_discount_percent] = 5

Setting.defaults[:sac_beginning_working_hour] = "08:00:00"
Setting.defaults[:sac_end_working_hour] = "19:00:00"
Setting.defaults[:sac_purchase_amount_threshold] = "69.9"
Setting.defaults[:sac_total_discount_threshold_percent] = "60"
Setting.defaults[:sac_billet_subscribers] = "diogo.silva@olook.com.br,claudia.sardano@olook.com.br"
Setting.defaults[:sac_fraud_subscribers] = "diogo.silva@olook.com.br,marcelo.azevedo@olook.com.br"
Setting.defaults[:whitelisted_emails_only] = false
Setting.defaults[:mark_notified_users] = true
Setting.defaults[:send_in_cart_mail_locally] = false
Setting.defaults[:checkout_suggested_product_id]= "12472"
Setting.defaults[:braspag_whitelisted_only] = true
Setting.defaults[:braspag_percentage] = 0
Setting.defaults[:braspag_rebuyers] = true

Setting.defaults[:acquirer] = "redecard"
# Settings for in_cart_mail process
Setting.defaults[:in_cart_mail_range] = "1"
Setting.defaults[:in_cart_mail_how_long] = "1"
Setting.defaults[:in_cart_mail_condition] = "notified=0"


Setting.defaults[:quantity_for_sugested_product]= (1..5)

# Gifts page
Setting.defaults[:profile_moderna_product_ids] = "4999,5759,3515,4352,7759"
Setting.defaults[:profile_casual_product_ids] = "9950,7434,7425,7001,6023"
Setting.defaults[:profile_chic_product_ids] = "6727,4963,5008,9896,9081"
Setting.defaults[:profile_sexy_product_ids] = "5044,5017,10022,4350,9406"

# ClearSale
Setting.defaults[:send_to_clearsale] = false
Setting.defaults[:force_send_to_clearsale] = false
Setting.defaults[:use_clearsale_server] = false

# General configs
Setting.defaults[:show_campaign_email_modal] = true

# First Purchase Discount Dates
Setting.defaults[:discount_period_in_days] = 7
Setting.defaults[:discount_period_expiration_warning_in_days] = 2
Setting.defaults[:lower_limit_expiration_date] = "2012-12-12"
Setting.defaults[:recommended_products] = "11101"
Setting.defaults[:default_item_quantity] = 10
Setting.defaults[:home_top5] = "5044,5017,10022,4350,9406"
Setting.defaults[:home_selection] = "5044,5017,10022,4350,9406"

#Showroom Settings
Setting.defaults[:showroom_active_fb_like_buttons] = false

# Featured products
Setting.defaults[:featured_shoe_label] = "Sapatos mais vendidos"
Setting.defaults[:featured_shoe_ids] = "12963,12981,12194,12203,8554,8572"
Setting.defaults[:featured_bag_label] = "Bolsas mais vendidas"
Setting.defaults[:featured_bag_ids] = "11449,11461,11467,11437,11189,11501,11229"
Setting.defaults[:featured_accessory_label] = "Acessorios mais vendidos"
Setting.defaults[:featured_accessory_ids] = "13179,14082,13255,13173,13165"
Setting.defaults[:featured_cloth_label] = "Roupas mais vendidas"
Setting.defaults[:featured_cloth_ids] = "90004,90092,90326"

# Image cache settings
Setting.defaults[:image_expiration_period_in_days] = "1"
