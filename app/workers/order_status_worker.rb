# -*- encoding : utf-8 -*-
class OrderStatusWorker
  @queue = :order_status

  def self.perform(order_id)
    order = Order.find(order_id)
    send_email(order)
    integrate_with_abacos(order)
  end

  def self.send_email(order)
    if order.waiting_payment?
      mail = OrderStatusMailer.order_requested(order)
    elsif order.authorized?
      mail = OrderStatusMailer.payment_confirmed(order)
    elsif order.canceled? || order.reversed?
      if order.payment.credit_card?
        mail = OrderStatusMailer.payment_refused(order)
      end
    end
    mail.deliver if mail
  end

  def self.integrate_with_abacos(order)
    if order.waiting_payment?
      create_order_event(order, "Enqueue Abacos::InsertOrder")
      Resque.enqueue(Abacos::InsertOrder, order.number)

    elsif order.authorized?
      create_order_event(order, "Enqueue Abacos::ConfirmPayment")
      Resque.enqueue_in(15.minutes, Abacos::ConfirmPayment, order.number)

    elsif order.canceled?
      create_order_event(order, "Enqueue Abacos::CancelOrder")
      Resque.enqueue_in(15.minutes, Abacos::CancelOrder, order.number)
    end
  end

  def self.create_order_event(order, msg)
    order.order_events.create(:message => msg)
  end
end
