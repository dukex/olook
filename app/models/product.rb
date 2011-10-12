# -*- encoding : utf-8 -*-
class Product < ActiveRecord::Base
  has_enumeration_for :category, :with => Category, :required => true
  
  has_many :pictures
  
  validates :name, :presence => true
  validates :description, :presence => true
  
  scope :shoes , where(:category => Category::SHOE)
  scope :bags  , where(:category => Category::BAG)
  scope :jewels, where(:category => Category::JEWEL)
end
