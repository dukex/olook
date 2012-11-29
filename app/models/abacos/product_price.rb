# -*- encoding : utf-8 -*-
module Abacos
  class ProductPrice
    attr_reader :integration_protocol, :model_number, :price, :retail_price

    def initialize(parsed_data)
      parsed_data.each do |key, value|
        self.instance_variable_set "@#{key}", value
      end
    end
    
    def integrate
      product = ::Product.find_by_model_number(self.model_number)
      raise RuntimeError.new "Price is related with Product model number #{self.model_number}, but it doesn't exist" if product.nil?
      
      product.price = self.price
      product.retail_price = self.retail_price
      if product.save!
        CatalogService.save_product product, :update_price => true
      end

      if product.is_kit
        update_kit_variant_price
      else
        confirm_price
      end

    end
    
    def confirm_price
      Resque.enqueue(Abacos::ConfirmPrice, self.integration_protocol)
    end

    def update_kit_variant_price
      parsed_data = { integration_protocol: self.integration_protocol,
        number:               self.model_number,
        price:                self.price,
        retail_price:         self.retail_price
      }

      Resque.enqueue(Abacos::IntegratePrice, Abacos::VariantPrice.to_s, parsed_data)
    end

    def self.parse_abacos_data(abacos_product)
      { integration_protocol: abacos_product[:protocolo_preco],
        model_number:         abacos_product[:codigo_produto],
        price:                abacos_product[:preco_tabela].to_f,
        retail_price:         abacos_product[:preco_promocional].to_f
      }
    end
  end
end