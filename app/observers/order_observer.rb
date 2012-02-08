# -*- encoding : utf-8 -*-
class OrderObserver < ActiveRecord::Observer
  def after_save(order)
    if order.state == "authorized"
     order.invalidate_coupon
    end
    order_inventory = OrderInventory.new(order)
    order_inventory.rollback if order_inventory.available_for_rollback?
    Resque.enqueue(OrderStatusWorker, order.id) if order.payment
  end
end