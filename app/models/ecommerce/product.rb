# -*- encoding : utf-8 -*-
class Product < ActiveRecord::Base
  SUBCATEGORY_TOKEN, HEEL_TOKEN = "Categoria", "Salto/Tamanho"
  UNAVAILABLE_ITEMS = :unavailable_items
  # TODO: Temporarily disabling paper_trail for app analysis
  #has_paper_trail :skip => [:pictures_attributes, :color_sample]
  QUANTITY_OPTIONS = {1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5}
  MINIMUM_VARIANTS_FOR_XML = 3
  MINIMUM_INVENTORY_FOR_XML = 3
  has_enumeration_for :category, :with => Category, :required => true

  after_create :create_master_variant
  after_update :update_master_variant

  has_many :pictures, :dependent => :destroy
  has_many :details, :dependent => :destroy
  # , :conditions => {:is_master => false}
  has_many :variants, :dependent => :destroy do
    def sorted_by_description
      self.sort {|variant_a, variant_b| variant_a.description <=> variant_b.description }
    end
  end

  # has_one :master_variant, :class_name => "Variant", :conditions => {:is_master => true}, :foreign_key => "product_id"
  # has_one :main_picture, :class_name => "Picture", :conditions => {:display_on => DisplayPictureOn::GALLERY_1}, :foreign_key => "product_id"

  belongs_to :collection
  has_and_belongs_to_many :profiles

  has_many :lookbooks_products, :dependent => :destroy
  has_many :lookbooks, :through => :lookbooks_products
  has_many :lookbook_image_maps, :dependent => :destroy
  has_many :liquidation_products
  has_many :liquidations, :through => :liquidation_products
  has_many :catalog_products, :class_name => "Catalog::Product", :foreign_key => "product_id"
  has_many :catalogs, :through => :catalog_products

  validates :name, :presence => true
  validates :description, :presence => true
  validates :model_number, :presence => true, :uniqueness => true

  mount_uploader :color_sample, ColorSampleUploader

  scope :only_visible , where(:is_visible => true)
  scope :valid_for_xml, lambda { only_visible.joins(" INNER JOIN(SELECT product_id, SUM(inventory) AS \"sum_inventory\", count(id) AS \"sum_variants\" from variants WHERE variants.price > 0.0 GROUP BY product_id) AS x ON products.id = x.product_id").where("x.sum_inventory > #{MINIMUM_INVENTORY_FOR_XML} AND x.sum_variants > #{MINIMUM_VARIANTS_FOR_XML} AND products.id NOT IN (:blacklist)", :blacklist => CRITEO_CONFIG["products_blacklist"]).order("collection_id desc")}
  scope :shoes        , where(:category => Category::SHOE)
  scope :bags         , where(:category => Category::BAG)
  scope :accessories  , where(:category => Category::ACCESSORY)

  scope :in_category, lambda { |value| { :conditions => ({ category: value } unless value.blank? || value.nil?) } }
  scope :in_collection, lambda { |value| { :conditions => ({ collection_id: value } unless value.blank? || value.nil?) } }
  scope :search, lambda { |value| { :conditions => ([ "name like ? or model_number = ?", "%#{value}%", value ] unless value.blank? || value.nil?) } }

  def self.in_profile profile
    !profile.blank? && !profile.nil? ? scoped.joins('inner join products_profiles on products.id = products_profiles.product_id').where('products_profiles.profile_id' => profile) : scoped
  end

  accepts_nested_attributes_for :pictures, :reject_if => lambda{|p| p[:image].blank?}

  def product_id
    id
  end

  def related_products
    products_a = RelatedProduct.select(:product_a_id).where(:product_b_id => self.id).map(&:product_a_id)
    products_b = RelatedProduct.select(:product_b_id).where(:product_a_id => self.id).map(&:product_b_id)
    Product.where(:id => (products_a + products_b))
  end

  def unrelated_products
    scope = Product.where("id <> :current_product", current_product: self.id)
    related_ids = related_products.map &:id
    scope = scope.where("id NOT IN (:related_products)", related_products: related_products) unless related_ids.empty?
    scope
  end

  def is_related_to?(other_product)
    related_products.include? other_product
  end

  def relate_with_product(other_product)
    return other_product if is_related_to?(other_product)

    RelatedProduct.create(:product_a => self, :product_b => other_product)
  end

  def unrelate_with_product(other_product)
    if is_related_to?(other_product)
      relationship = RelatedProduct.where("((product_a_id = :current_product) AND (product_b_id = :other_product)) OR ((product_b_id = :current_product) AND (product_a_id = :other_product))",
        current_product: self.id, other_product: other_product.id).first
      relationship.destroy
    end
  end

  delegate :price, to: :master_variant
  delegate :'price=', to: :master_variant
  delegate :retail_price, to: :master_variant
  delegate :'retail_price=', to: :master_variant
  delegate :width, to: :master_variant
  delegate :'width=', to: :master_variant
  delegate :height, to: :master_variant
  delegate :'height=', to: :master_variant
  delegate :length, to: :master_variant
  delegate :'length=', to: :master_variant
  delegate :weight, to: :master_variant
  delegate :'weight=', to: :master_variant
  delegate :discount_percent, to: :master_variant
  delegate :'discount_percent=', to: :master_variant

  def main_picture
    picture = self.pictures.where(:display_on => DisplayPictureOn::GALLERY_1).first
  end

  def thumb_picture
    main_picture.try(:image_url, :thumb) # 50x50
  end

  def bag_picture
    main_picture.try(:image_url, :bag) # 70x70
  end

  def showroom_picture
    main_picture.try(:image_url, :showroom) # 170x170
  end

  def suggestion_picture
    main_picture.try(:image_url, :suggestion) # 260x260
  end

  def master_variant
    @master_variant ||= Variant.unscoped.where(:product_id => self.id, :is_master => true).first
  end

  def colors
    self.related_products.where(:category => self.category, :name => self.name)
  end

  def all_colors
    ([self] + self.colors).sort_by {|product| product.id }
  end

  def easy_to_find_description
    "#{model_number} - #{name} - #{color_name} - #{category_humanize}"
  end

  def inventory
    self.variants.sum(:inventory)
  end

  def sold_out?
    inventory < 1
  end

  def quantity ( size )
    self.variants.each do |variant|
      if variant.description.to_i == size
        return variant.inventory.to_i
      end
    end
    return 0
  end

  def instock
    sold_out? ? "0" : "1"
  end

  def liquidation?
    active_liquidation = LiquidationService.active
     active_liquidation.has_product?(self) if active_liquidation
  end

  def promotion?
    price != retail_price
  end

  def promotion_price
    PromotionService.by_product(self)
  end

  def gift_price(position = 0)
    GiftDiscountService.price_for_product(self,position)
  end

  def product_url(options = {})
    params =
    {
      :host => "www.olook.com.br",
      :utm_medium => "vitrine",
      :utm_campaign => "produtos",
      :utm_content => id
    }
    Rails.application.routes.url_helpers.product_url(self, params.merge!(options))
  end

  def self.remove_color_variations(products)
    result = []
    already_displayed = []
    displayed_and_sold_out = {}

    products.each do |product|
      # Only add to the list the products that aren't already shown
      unless already_displayed.include?(product.name)
        result << product
        already_displayed << product.name
        displayed_and_sold_out[product.name] = result.length - 1 if product.sold_out?
      else
        # If a product of the same color was already displayed but was sold out
        # and the algorithm find another color that isn't, replace the sold out one
        # by the one that's not sold out
        if displayed_and_sold_out[product.name] && !product.sold_out?
          result[displayed_and_sold_out[product.name]] = product
          displayed_and_sold_out.delete product.name
        end
      end
    end
    result
  end

  def subcategory
    subcategory_name
  end

  def subcategory_name
    detail_by_token SUBCATEGORY_TOKEN
  end

  def heel
    detail_by_token HEEL_TOKEN
  end

  def shoe?
    self.category == ::Category::SHOE
  end

  def variant_by_size(size)
    case self.category
    when Category::SHOE then
      self.variants.where(:display_reference => "size-#{size}").first
    else
      self.variants.last
    end
  end

private

  def create_master_variant
    @master_variant = Variant.new(:is_master => true,
                                  :product => self,
                                  :number => "master#{self.model_number}",
                                  :description => 'master',
                                  :price => 0.0, :inventory => 0,
                                  :width => 0, :height => 0, :length => 0,
                                  :display_reference => 'master',
                                  :weight => 0.0 )
    @master_variant.save!
  end

  def update_master_variant
    master_variant.save!
  end

  def detail_by_token token
    detail = self.details.where(:translation_token => token).last
    detail.description if detail
  end

end
