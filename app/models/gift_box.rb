# == Schema Information
#
# Table name: gift_boxes
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  active      :boolean
#  thumb_image :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class GiftBox < ActiveRecord::Base
  include ProductFinder

  validates :name, :presence => true
  mount_uploader :thumb_image, ImageUploader
  has_many :gift_boxes_product, :dependent => :destroy
  has_many :products, :through => :gift_boxes_product
  attr_accessor :product_list
  after_save :update_products

  def suggestion_products
    products_to_show = remove_color_variations(products)
    products_to_show.sort_by{|p| p.inventory}.reverse.first(5)
  end

  private

  def update_products
    products.delete_all unless product_list.nil?
    selected_products = product_list.nil? ? [] : product_list.keys.collect{|id| Product.find_by_id(id)}
    selected_products.each {|os| self.products << os}
    lb = self.products
  end
end
