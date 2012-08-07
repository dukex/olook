# -*- encoding : utf-8 -*-
class Billet < Payment

  EXPIRATION_IN_DAYS = 3
  validates :receipt, :presence => true, :on => :create
  after_create :set_payment_expiration_date, :notify_sac

  state_machine :initial => :started do
    after_transition :started => :billet_printed, :do => :notify_sac
    after_transition :billet_printed => :authorized, :do => :authorize_order
    after_transition :authorized => :under_review, :do => :review_order
    after_transition :under_review => :refunded, :do => :refund_order
    after_transition :started => :canceled, :do => :cancel_order
    after_transition :billet_printed => :canceled, :do => :cancel_order

    event :started do
      transition :started => :started
    end

    event :billet_printed do
      transition :started => :billet_printed
    end

    event :authorized do
      transition :billet_printed => :authorized
    end

    event :canceled do
      transition :started => :canceled, :billet_printed => :canceled
    end

    event :completed do
      transition :authorized => :completed, :under_review => :completed
    end

    event :under_review do
      transition :authorized => :under_review
    end

    event :refunded do
      transition :under_review => :refunded
    end
  end

  def notify_sac
    # SAC::Notifier.notify(SAC::Notification.new(:billet, "Pedido: #{self.order.number} | Boleto", self.order)) if self.order
  end

  def to_s
    "BoletoBancario"
  end

  def human_to_s
    "Boleto Bancário"
  end

  def expired_and_waiting_payment?
    (self.expired? && self.order.waiting_payment?) ? true : false
  end

  def expired?
    Date.current > BilletExpirationDate.expiration_for_two_business_day(self.payment_expiration_date.to_date) if self.payment_expiration_date
  end

  private

  def build_payment_expiration_date
    BilletExpirationDate.expiration_for_two_business_day
  end
end
