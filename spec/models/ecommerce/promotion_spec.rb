require 'spec_helper'

describe Promotion do

  let!(:promo) { FactoryGirl.create(:first_time_buyers, starts_at: Date.today-1.day, ends_at: Date.today+1.day) }
  let!(:another_promo) { FactoryGirl.create(:compre_3_pague_2, starts_at: Date.today-1.day, ends_at: Date.today+1.day) }
  let(:cart) { FactoryGirl.build(:cart_with_items) }
  let(:user) { FactoryGirl.build(:user) }

 describe "#validations" do

   it { should have_many :rule_parameters }
   it { should have_many(:promotion_rules).through(:rule_parameters)}
   it { should have_one :action_parameter }
   it { should have_one(:promotion_action).through(:action_parameter)}
 end

 describe "#apply" do
   context "when promotion has action parameter with param" do
     it "returns true" do
       subject.should respond_to(:apply).with(1).argument
     end
   end
 end

 describe "#simulate" do
   context "when there's promotion to simulate" do
     it "returns true" do
       ac = FactoryGirl.create(:promotion_action)
       promo.promotion_action = ac
       promo.promotion_action.should respond_to(:simulate).with(2).arguments
     end
   end
 end

  describe ".select_promotion_for" do
    context "when there's promotion and cart to apply" do

      before :each do
        promo.stub(:simulate).and_return(10.5)
        another_promo.stub(:simulate).and_return(5.5)
        described_class.stub(:matched_promotions_for).and_return([promo, another_promo])
      end

      it "retuns best promotion" do
        described_class.select_promotion_for(cart).should eq(promo)
      end
    end
  end
end
