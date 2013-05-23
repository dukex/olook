# -*- encoding : utf-8 -*-
module Abacos
  class IntegrateProducts
    @queue = :product

    def self.perform(user="tech@olook.com.br")
      return true unless Setting.abacos_invetory
      
      products_amount = process_products
      process_prices


      opts = {
        to: user, 
        subject: 'Sincronização de produtos concluída', 
        body: "Quantidade de produtos integrados: #{products_amount}"
      }

      DevAlertMailer.notify(opts).deliver
    end

  private
    def self.process_products
      products = ProductAPI.download_products
      products.each do |abacos_product|
        begin
          parsed_class = parse_product_class(abacos_product)
          parsed_data = parsed_class.parse_abacos_data(abacos_product)
          Resque.enqueue(Abacos::Integrate, parsed_class.to_s, parsed_data)
        rescue Exception => e
          Airbrake.notify(
            :error_class   => "Abacos product integration",
            :error_message => e.message
          )
        end
      end
      products.size
    end

    def self.process_prices
      ProductAPI.download_prices.each do |abacos_price|
        begin
          parsed_class = parse_price_class(abacos_price)
          parsed_data = parsed_class.parse_abacos_data(abacos_price)
          Resque.enqueue(Abacos::IntegratePrice, parsed_class.to_s, parsed_data)
        rescue Exception => e
          Airbrake.notify(
            :error_class   => "Abacos price integration",
            :error_message => e.message
          )
        end
      end
    end
    
  private
    def self.parse_product_class(abacos_product)
      is_product?(abacos_product) ? Abacos::Product : Abacos::Variant
    end

    def self.parse_price_class(abacos_product)
      is_product?(abacos_product) ? Abacos::ProductPrice : Abacos::VariantPrice
    end

    def self.is_product?(abacos_product)
      abacos_product[:codigo_produto_pai].nil? || abacos_product[:codigo_produto_pai] == abacos_product[:codigo_produto]
    end
  end
end
