# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class Role < ActiveRecord::Base

  # TODO: Temporarily disabling paper_trail for app analysis
  #has_paper_trail :on => [:update, :destroy]

  has_many :admins
  has_and_belongs_to_many :permissions
  validates :name, :uniqueness => true
  validates :name, :description, :presence => true
  validates :name, :uniqueness => true

  def permissions_attributes=(new_permissions_attributes)
    self.permissions = PermissionMapBuilder.new(self.permissions).map(new_permissions_attributes)
  end

  def has_permission?(permission_id)
    self.permissions.include?(Permission.find(permission_id)) ? true : false
  end


end
