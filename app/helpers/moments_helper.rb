# -*- encoding : utf-8 -*-
module MomentsHelper
  MIN_INSTALLMENT_VALUE = 30
  MAX_INSTALLMENT_NUMBER = 10

  def msn_tags
    image_tag "http://view.atdmt.com/action/mmn_olook_colecoes#{@moment.id}", size: "1x1"
  end

  def installments(price)
    installments = number_of_installments_for(price)
    installment_price = price / installments
    "#{installments} x de #{number_to_currency(installment_price)}"
  end

  private 
    def number_of_installments_for price
      return 1 if price <= MIN_INSTALLMENT_VALUE
      return MAX_INSTALLMENT_NUMBER if price >= MIN_INSTALLMENT_VALUE * MAX_INSTALLMENT_NUMBER

      price.to_i / MIN_INSTALLMENT_VALUE
    end

end
