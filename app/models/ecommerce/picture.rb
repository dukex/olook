# -*- encoding : utf-8 -*-
class Picture < ActiveRecord::Base
  belongs_to :product
  validates :product, :presence => true
  has_enumeration_for :display_on, :with => DisplayPictureOn, :required => true
  mount_uploader :image, PictureUploader
  after_update :invalidate_cdn_image

  private

  def invalidate_cdn_image
    CloudfrontInvalidator.new.invalidate(self.image.url.slice(23..150)) unless self.image.url.nil?
  end
end

