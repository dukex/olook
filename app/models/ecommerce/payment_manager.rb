# -*- encoding: utf-8 -*-
class PaymentManager
  attr_accessor :billet, :credit_card, :debit

  def initialize
    @billet, @credit_card, @debit = "Billet", "CreditCard", "Debit"
  end

  def expires_billet
    search_and_cancel(@billet)
  end

  def expires_credit_card
    search_and_cancel(@credit_card)
  end

  def expires_debit
    search_and_cancel(@debit)
  end

  def self.http_get_in_payment_url_to_force_generation(payment)
    url = URI.parse payment.url
    Net::HTTP.get url
  end

  private

  def search_and_cancel(payment_type)
    Payment.where(:type => payment_type).find_each do |payment|
      if payment.order
        if payment.expired_and_waiting_payment?
            payment.canceled
        end
      end
    end
  end
end
