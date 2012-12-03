# == Schema Information
#
# Table name: addresses
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  country      :string(255)
#  city         :string(255)
#  state        :string(255)
#  complement   :string(255)
#  street       :string(255)
#  number       :integer
#  neighborhood :string(255)
#  zip_code     :string(255)
#  telephone    :string(255)
#  first_name   :string(255)
#  last_name    :string(255)
#  mobile       :string(255)
#

class Address < ActiveRecord::Base
  belongs_to :user
  has_many :freights

  STATES = ["AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO"]

  ZipCodeFormat = /^[0-9]{5}-[0-9]{3}$/
  PhoneFormat = /^(?:\(11\)9\d{4}-\d{3,4}|\(\d{2}\)\d{4}-\d{4})$/
  MobileFormat = /^(?:\(11\)9\d{4}-\d{3,4}|\(\d{2}\)\d{4}-\d{4})$/
  StateFormat = /^[A-Z]{2}$/

  validates_presence_of :country, :state, :street, :city, :number, :zip_code, :neighborhood, :telephone

  validates :number, :numericality => true, :presence => true
  validates :zip_code, :format => {:with => ZipCodeFormat}
  validates :telephone, :format => {:with => PhoneFormat}, :if => :telephone?
  validates :mobile, :format => { :with => MobileFormat }, :if => :mobile?
  validates :state, :format => {:with => StateFormat}
  before_validation :normalize_street

  def identification
    "#{first_name} #{last_name}"
  end

  private
  def normalize_street
    self.street = "Rua #{ self.street }" if (self.street && self.street.length == 1)
  end
end
