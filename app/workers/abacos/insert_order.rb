# -*- encoding : utf-8 -*-
module Abacos
  class InsertOrder
    @queue = 'medium'

    def self.perform(order_number)
      Rails.logger.info("[BUG] integrating order:#{order_number}")
      return true unless Setting.abacos_integrate
      
      order = parse_and_check_order order_number
      if export_client(order)
        if insert_order(order)
          Resque.enqueue(Abacos::CancelOrder, order_number) if order.canceled?
        end
      end
      Rails.logger.info("[BUG] order:#{order} integrated successfully")
    end

  private
    def self.parse_and_check_order(order_number)
      order = Order.find_by_number order_number
      raise "Order number #{order_number} doesn't have an associated payment" unless order.erp_payment
      raise "Order number #{order_number} already exist on Abacos" if Abacos::OrderAPI.order_exists?(order_number)
      Rails.logger.info("[BUG] Found order:#{order.inspect}")
      order
    end

    def self.export_client(order)
      Rails.logger.info("[BUG] freight:#{order.freight.inspect}")
      Rails.logger.info("[BUG] address:#{order.freight.address.inspect}")
      cliente = Abacos::Cliente.new order.user, order.freight.address
      Abacos::ClientAPI.export_client cliente
    end

    def self.insert_order(order)
      pedido = !order.gift_wrap? ? Abacos::Pedido.new(order) : Abacos::PedidoPresente.new(order)
      Abacos::OrderAPI.insert_order pedido
    end
  end
end
