class Coupon < ActiveRecord::Base
  # TODO: Temporarily disabling paper_trail for app analysis
  #has_paper_trail :on => [:update, :destroy]

  COUPON_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/coupons.yml")
  PRODUCT_COUPONS_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/product_coupons.yml")[Rails.env]
  BRAND_COUPONS_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/brand_coupons.yml")[Rails.env]
  MODAL_POSSIBLE_VALUES = [1,2,3]

  validates_presence_of :code, :value, :start_date, :end_date, :campaign, :created_by
  validates_presence_of :remaining_amount, :unless => Proc.new { |a| a.unlimited }
  validates_uniqueness_of :code
  has_many :coupon_payments
  has_many :carts

  before_save :set_limited_or_unlimited

  def modal=(val)
    if MODAL_POSSIBLE_VALUES.include?(val.to_i)
      write_attribute(:modal, val.to_i)
    else
      write_attribute(:modal, 1)
    end
  end

  def available?
    (active_and_not_expired?) ? true : false
  end

  def expired?
    true unless self.start_date < Time.now && self.end_date > Time.now
  end

  def discount_percent
    self.is_percentage? ? self.value : 0
  end

  def apply_discount_to? product

    if coupon_specific_for_product?
      product_ids = product_ids_allowed_to_have_discount
      product_ids.include?(product.id.to_s)
    elsif coupon_specific_for_brand?
      product.brand.downcase == brand.downcase
    else
      true
    end

  end

  def should_apply_to?(cart)
    discounts_sum = cart.total_promotion_discount + cart.total_liquidation_discount(ignore_coupon: true)
    calculated_value(cart.total_price) > discounts_sum
  end

  private
    def coupon_specific_for_product?
      !product_ids_allowed_to_have_discount.nil?
    end

    def coupon_specific_for_brand?
      !brand.nil?
    end

    def product_ids_allowed_to_have_discount
      product_ids = PRODUCT_COUPONS_CONFIG[self.code]
      product_ids ? product_ids.split(",") : nil
    end

    def active_and_not_expired?
      if self.active? && !expired?
        (ensures_regardless_status) ? true : false
      end
    end

    def set_limited_or_unlimited
      if self.remaining_amount.nil?
        self.unlimited = true
      else
        self.unlimited = nil
      end
    end

    def ensures_regardless_status
      true if self.unlimited? || self.remaining_amount > 0
    end

    def calculated_value(total_price)
      is_percentage ? convert_percentage(total_price) : value
    end

    def convert_percentage(total_price)
      total_price * (value / 100)
    end

end
