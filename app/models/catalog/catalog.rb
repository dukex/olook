class Catalog::Catalog < ActiveRecord::Base
  has_many :products, :class_name => "Catalog::Product", :foreign_key => "catalog_id"

  validates :type, :presence => true, :exclusion => ["Catalog::Catalog"]

  def in_category(category_id)
    @liquidation = LiquidationService.active
    @query = products.joins(:product)
    @query = @query.joins('left outer join liquidation_products on liquidation_products.product_id = catalog_products.product_id') if @liquidation
    @query = @query.where(category_id: category_id, products: {is_visible: 1}).where("catalog_products.inventory > 0")

    @query = @query.where(liquidation_products: {product_id: nil}) if @liquidation
    @query
  end

  def subcategories(category_id)
    in_category(category_id).group(:subcategory_name).order("subcategory_name asc").map { |p| [p.subcategory_name, p.subcategory_name_label] }.compact
  end

  def shoes
    subcategories(Category::SHOE)
  end

  def bags
    subcategories(Category::BAG)
  end

  def accessories
    subcategories(Category::ACCESSORY)
  end

  def clothes
    subcategories(Category::CLOTH)
  end

  def shoe_sizes
    in_category(Category::SHOE).group(:shoe_size).order("shoe_size asc").map { |p| p.shoe_size }.compact
  end

  def cloth_sizes
    in_category(Category::CLOTH).group(:cloth_size).order("cloth_size asc").map { |p| p.cloth_size }.compact
  end

  def heels
    in_category(Category::SHOE).group(:heel).order("heel asc").map { |p| [p.heel, p.heel_label] if p.heel }.compact.sort{ |a,b| a[0].to_i <=> b[0].to_i }
  end
end
