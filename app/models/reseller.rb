class Reseller < User
  attr_accessible :cnpj, :active, :reseller, :corporate_name, :has_corporate, :birthday, :gender, :addresses_attributes
  scope :all_reseller, where(reseller: true)
  validates :gender, :birthday, presence: true
  validates :has_corporate, :inclusion => { :in => [true, false] }
  validates_presence_of :cnpj, :corporate_name, if: Proc.new { |reseller| reseller.has_corporate == true }
  accepts_nested_attributes_for :addresses
  usar_como_cnpj :cnpj
end
