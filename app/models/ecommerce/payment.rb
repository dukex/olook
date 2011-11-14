# -*- encoding : utf-8 -*-
class Payment < ActiveRecord::Base
  attr_accessor :name, :credit_card_number
  TYPE = {:billet => 1, :debit => 2, :credit => 3}
  belongs_to :order
  validates_presence_of :payment_type, :name, :credit_card_number
end
