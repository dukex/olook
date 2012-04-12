class GiftOccasionType < ActiveRecord::Base
  has_many :gift_occasions
  validates :name, :presence => true, :length => {:minimum => 2}
end
