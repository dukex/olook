# -*- encoding : utf-8 -*-
module FreightCalculator
  VALID_ZIP_FORMAT = /\A(\d{8})\z/
  VALID_SHIPPING_SERVICES_ID_LIST = /^(\d+,?)*$/

  DEFAULT_FREIGHT_PRICE   = 0.0
  DEFAULT_FREIGHT_COST    = 0.0
  DEFAULT_INVENTORY_TIME  = 1
  DEFAULT_FREIGHT_SERVICE = 2 # CORREIOS

  DEFAULT_FREIGHT = {
    default_shipping: {
      price: DEFAULT_FREIGHT_PRICE, 
      cost: DEFAULT_FREIGHT_COST,
      delivery_time: DEFAULT_INVENTORY_TIME + 4,
      shipping_service_id: DEFAULT_FREIGHT_SERVICE
    }
  }


  def self.freight_for_zip(zip_code, order_value, shipping_service_ids = nil, use_message = false)
    clean_zip_code = clean_zip(zip_code)
    return {} unless valid_zip?(clean_zip_code)
    order_value = 1 if order_value == 0
    return_array = []
    shipping_service_ids = ShippingService.all.map(&:id) if shipping_service_ids.blank?
    freight_prices = FreightPrice.with_zip_and_value(clean_zip_code,order_value, shipping_service_ids)
    return DEFAULT_FREIGHT if freight_prices.blank?
    freight_prices.compact.each do |freight|
      return_array << {
      :price => freight.try(:price) || DEFAULT_FREIGHT_PRICE,
      :cost => freight.try(:cost) || DEFAULT_FREIGHT_COST,
      :delivery_time => (freight.try(:delivery_time) || 0) + DEFAULT_INVENTORY_TIME,
      :shipping_service_id => freight.try(:shipping_service_id) || DEFAULT_FREIGHT_SERVICE,
      :cost_for_free => (freight.price != 0.0) && use_message ? FreightPrice.free_cost(clean_zip_code, order_value,freight.shipping_service_id).first.try(:order_value_start) : ''
    }
    end
    TransportShippingService.new(return_array).choose_better_transport_shipping
  end

  def self.valid_zip?(zip_code)
    return unless zip_code
    zip_code.to_s.match(VALID_ZIP_FORMAT) ? true : false
  end

  def self.clean_zip(dirty_zip)
    return dirty_zip.to_s.gsub(/\D/, '')
  end

  private
    def self.shipping_services(shipping_service_ids)

      sanitized_list = sanitize(shipping_service_ids)
      if sanitized_list.any?
        ShippingService.where(id: sanitized_list)
      else
        ShippingService.order('priority')
      end
    end

    def self.sanitize list
      VALID_SHIPPING_SERVICES_ID_LIST =~ list ? list.split(",") : []
    end

end
