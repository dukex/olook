class UserLiquidation < ActiveRecord::Base
  belongs_to :user
  belongs_to :liquidation
end
