# encoding: utf-8
class PromotionAction < ActiveRecord::Base
  validates :type, presence: true
  has_many :action_parameters

  @filters = {
    param: { desc: 'Parâmetro da Ação', kind: 'string' },
    brand: { desc: 'Só descontar produtos dessas marcas', kind: 'string' },
    full_price: { desc: 'Só descontar produtos com preço cheio (sem markdown)', kind: 'boolean', default: '1' }
  }

  def self.filters
    @filters ||= PromotionAction.filters.dup
  end

  def self.default_filters
    @default_filters ||= Hash[PromotionAction.filters.dup.to_a.map { |k, h| [k, h[:default]] }]
  end

  def apply(cart, param, match)
    calculate(cart.items, param).each do |item|
      adjustment = item[:adjustment]
      item = cart.items.find(item[:id])
      item.cart_item_adjustment.update_attributes(value: adjustment, source: "#{match.class}: #{match.name}") if item.should_apply?(adjustment)
    end
  end

  def simulate(cart, param)
    cart.items.any? ? calculate(cart.items, param).map{|item| item[:adjustment]}.reduce(:+) : 0
  end

  def simulate_for_product(product, cart, param)
    if cart.items.any?
      _calc = calculate(cart.items, param)
      _c = _calc.find { |item| item[:product_id] == product.id }
      return _c ? _c[:adjustment] : 0
    end
    0
  end

  def desc_value(filters); end
  protected
  #
  # This method should return an Array of Hashes in the form:
  # => [{id: item.id, product_id: item.product.id, adjustment: item.price}]
  #
  def calculate(cart, param); end


  def filter_items(cart_items, filters)
    cis = cart_items.dup
    if filters['brand'].present?
      brands = Set.new(filters['brand'].to_s.split(/[\n\s]*,[\n\s]*/).map { |w| w.strip.parameterize })
      cis.select! { |item| brands.include?(item.product.brand.strip.parameterize)  }
    end

    if filters['full_price'] == '1'
      cis.select! { |item| item.product.price == item.product.retail_price }
    end
    cis
  end
end
