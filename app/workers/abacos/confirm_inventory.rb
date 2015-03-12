# -*- encoding : utf-8 -*-
module Abacos
  class ConfirmInventory
    @queue = 'high'

    def self.perform(protocol)
      Abacos::ProductAPI.confirm_inventory protocol
    end
  end
end
