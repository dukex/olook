class Lookbook < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
  has_many :images, :dependent => :destroy
  has_many :lookbooks_products, :dependent => :destroy
  has_many :products, :through => :lookbooks_products
  has_one :video, :as => :video_relation, :dependent => :destroy

  has_many :lookbook_image_maps, :dependent => :destroy

  scope :active, where(active: 1).order("created_at DESC")

  accepts_nested_attributes_for :images, :reject_if => lambda{|p| p[:image].blank?}

  mount_uploader :thumb_image, ImageUploader

  mount_uploader :icon, ImageUploader
  mount_uploader :icon_over, ImageUploader

  mount_uploader :movie_image, LookbookPictureUploader

  attr_accessor :product_list
  attr_accessor :product_criteo
  after_save :update_products

  def has_video?
    self.video.nil? == false
  end

  private

  def update_products
    products.delete_all unless product_list.nil?
    selected_products = product_list.nil? ? [] : product_list.keys.collect{|id| Product.find_by_id(id)}
    selected_products.each {|os| self.products << os}
    lb = self.lookbooks_products
    lb.each do |lb_product|

      if !product_criteo.nil?
        product_criteo.each do |key, val|
          if lb_product.product_id == key.to_i
            lb_product.update_attribute(:criteo, val)
          end
        end
      end

    end
  end
end
