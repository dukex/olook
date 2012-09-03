require 'spec_helper'

describe PromotionService do

  let!(:user) {FactoryGirl.create(:user)}

  subject do
    PromotionService.new(user)
  end

  describe "should detect the current promotion when" do
    it "there is a user that matches the first time buyers" do
      promotion = FactoryGirl.create(:first_time_buyers)
      subject.detect_current_promotion.should == promotion
    end
  end

  describe "should not match any promotion" do
    it "when the user is not a first time buyers" do
      order = FactoryGirl.create(:delivered_order)
      promotion = FactoryGirl.create(:first_time_buyers)
      PromotionService.new(order.user).detect_current_promotion.should be_nil
    end
  end
end
