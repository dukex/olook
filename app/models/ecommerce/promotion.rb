class Promotion < ActiveRecord::Base
  validates_presence_of :name, :banner_label

  scope :active, where(:active => true)
  scope :active_and_not_expired, lambda {|date| active.where('starts_at <= :date AND ends_at >= :date', date: date)}

  has_many :promotion_payments

  has_many :rule_parameters
  has_many :promotion_rules, :through => :rule_parameters

  has_one :action_parameter
  has_one :promotion_action, through: :action_parameter

  accepts_nested_attributes_for :rule_parameters, :action_parameter

  def apply cart
    if should_apply_for? cart
      promotion_action.apply cart, self.action_parameter.action_params
      Rails.logger.info "Applied promotion: #{self.name} for cart [#{cart.id}]"
    end
  end

  def simulate cart
    promotion_action.simulate cart, self.action_parameter.action_params
  end

  def should_apply_for?(cart)
    cart.coupon ? is_greater_than_coupon?(cart) : true
  end

  def self.select_promotion_for(cart)
    promotions_to_apply = matched_promotions_for cart
    best_promotion_for(cart, promotions_to_apply)
  end

  def total_discount_for(cart)
    simulate(cart).map {|item| item[:adjust] }.reduce(:+)
  end

  private

    def self.matched_promotions_for cart
      promotions = []
      active_and_not_expired(Date.today).each do |promotion|
        matched_all_rules = promotion.promotion_rules.inject(true) do | match_result, rule |
          match_result &&= rule.matches?(cart.user)
        end

        promotions << promotion if matched_all_rules
      end
      promotions
    end

    def self.best_promotion_for(cart, promotions_to_apply = [])
      if cart.items.any? && promotions_to_apply.any?
        best_promotion = calculate(promotions_to_apply, cart).sort_by { |key, value| value }.last
        if best_promotion[:total_discount] && best_promotion[:total_discount] >= cart.total_coupon_discount
          best_promotion[:promotion]
        end
      end
    end

    def self.calculate(promotions_to_apply, cart)
      promotions = []
      promotions_to_apply.map do |promotion|
        promotions << {promotion: promotion, total_discount: promotion.total_discount_for(cart)}
      end
      promotions
    end

    def is_greater_than_coupon?(cart)
      total_discount_for(cart) > cart.coupon.value
    end
end
