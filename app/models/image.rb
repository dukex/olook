# == Schema Information
#
# Table name: images
#
#  id          :integer          not null, primary key
#  image       :string(255)
#  lookbook_id :integer
#  created_at  :datetime
#  updated_at  :datetime
#

# -*- encoding : utf-8 -*-
class Image < ActiveRecord::Base
	belongs_to :lookbook
  has_many :lookbook_image_maps
  
  validates :lookbook, :presence => true
  mount_uploader :image, ImageUploader
  after_update :invalidate_cdn_image

  private

  def invalidate_cdn_image
    CloudfrontInvalidator.new.invalidate(self.image.url.slice(23..150)) unless self.image.url.nil?
  end
end
