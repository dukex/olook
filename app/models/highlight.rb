# -*- encoding : utf-8 -*-
class Highlight < ActiveRecord::Base
  mount_uploader :image, CentralHighlightBannerUploader
  mount_uploader :left_image, SideHighlightBannerUploader
  mount_uploader :right_image, SideHighlightBannerUploader

  after_save :clean_cache
  after_destroy :clean_cache

  validates :link, presence: true
  validates :position, presence: true
  validates :title, presence: true
  validates :subtitle, presence: true
  validates :alt_text, presence: true
  validates :image, presence: true, if: :is_center_image?
  validates :left_image, presence: true, if: :is_left_image?
  validates :right_image, presence: true, if: :is_right_image?

  def self.highlights_to_show
    Rails.cache.fetch("highlights", :expires_in => 30.minutes) do
      highlights = {}
      for i in 1..3 
        highlights[i] = where(position: i).last
      end
      highlights
    end
  end

  def image_for_position
    case position
    when HighlightPosition::CENTER 
      image
    when HighlightPosition::LEFT
      left_image
    when HighlightPosition::RIGHT
      right_image
    end    
  end

  private

  def clean_cache
    Rails.cache.delete("highlights")
  end

  def is_center_image?
    position == HighlightPosition::CENTER
  end

  def is_left_image?
    position == HighlightPosition::LEFT
  end

  def is_right_image?
    position == HighlightPosition::RIGHT
  end
end
