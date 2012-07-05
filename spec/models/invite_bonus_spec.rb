# -*- encoding : utf-8 -*-
require 'spec_helper'

describe InviteBonus do
  before do
    Resque.stub(:enqueue)
    Resque.stub(:enqueue_in)
  end

  describe "when calculating the invite bonus" do
    let(:member) { FactoryGirl.create(:member) }

    describe "#for_being_invited" do
      it "should be R$ 10 for invited members" do
        member.stub(:'is_invited?').and_return(true)
        described_class.for_being_invited(member).should == 10.0
      end
      it "should be R$ 0 for uninvited members" do
        member.stub(:'is_invited?').and_return(false)
        described_class.for_being_invited(member).should == 0.0
      end
    end

    describe "#for_accepted_invites, when a user has 20 invites, 13 of which were accepted" do
      context "for invites accepted before 10th Nov 2011" do
        before :each do
          build_invites( DateTime.civil(2011, 11, 9, 9, 59, 59) )
        end

        it "should be R$ 10 for each accepted invitation, in this case R$ 130" do
          described_class.for_accepted_invites(member).should == 130.0
        end
      end

      context "invites accepted between 10th Nov 2011 and 20th Nov 2011" do
        before :each do
          build_invites( DateTime.civil(2011, 11, 10, 10, 0, 0) )
        end

        it "should be R$ 20 for every 5 accepted invitations, in this case R$ 40" do
          described_class.for_accepted_invites(member).should == 40.0
        end
      end


      context "invites accepted in 3rd Mar 2012" do
        before :each do
          build_invites( DateTime.civil(2012, 03, 03, 0, 0, 0) )
        end

        it "returns 0" do
          described_class.for_accepted_invites(member).should == 40.0
        end
      end

      context "invites accepted after 13th Mar 2012" do
        before :each do
          build_invites( DateTime.civil(2012, 03, 14, 0, 0, 0) )
        end

        it "returns 0" do
          described_class.for_accepted_invites(member).should == 0.0
        end
      end
    end

    describe "#already_used" do
      context "user has no orders" do
        let(:user) { FactoryGirl.create :user }
        it "returns R$ = 0.0" do
          described_class.already_used(user).should == 0
        end

        it "returns a float number" do
          described_class.already_used(user).should be_an_instance_of Float
        end
      end

      context "user has orders" do
        let!(:line_item) { [ FactoryGirl.create(:line_item, :price => 100.0) ] }
        let!(:order_1) { FactoryGirl.create(:order, :user => member, :line_items => line_item, :credits => 23.56 ) }
        let!(:order_2) { FactoryGirl.create(:order, :user => member, :line_items => line_item, :credits => 3.23 ) }
        let!(:order_3) { FactoryGirl.create(:order, :user => member, :line_items => line_item) }
        let!(:order_4) { FactoryGirl.create(:clean_order, :user => member, :line_items => line_item, :credits => 12.90 ) }

        it "should return the sum of credits used in the orders that have a payment" do
          described_class.already_used(member).should == 26.79
        end

        it "should return the sum of credits used in the orders that dont have a payment but have a current order" do
          described_class.already_used(member, order_4).should == 39.69
        end

        it "should return the sum of credits used in the orders and not count a canceled order" do
          order_2.canceled
          described_class.already_used(member).to_f.should == 23.56
        end

        it "should return the sum of credits used in the orders and not count a reversed order" do
          order_2.authorized
          order_2.under_review
          order_2.reversed
          described_class.already_used(member).to_f.should == 23.56
        end

        it "should return the sum of credits used in the orders and not count a reversed order" do
          order_2.authorized
          order_2.under_review
          order_2.refunded
          described_class.already_used(member).to_f.should == 23.56
        end
      end

    end

    describe "#calculate" do
      it "should be the sum of for_accepted_invites and for_being_invited minus already_used" do
        described_class.stub(:for_accepted_invites).and_return(123.0)
        described_class.stub(:for_being_invited).and_return(7.0)
        described_class.stub(:already_used).and_return(3.12)
        described_class.calculate(member).should == 126.88
      end

      it 'should be limited to R$ 300 no matter how many invites were accepted' do
        described_class.stub(:for_accepted_invites).and_return(100.0)
        described_class.stub(:for_being_invited).and_return(300.0)
        described_class.stub(:already_used).and_return(250.0)
        described_class.calculate(member).should == 50.0
      end
    end
  end

private
  def build_invites(accepted_at)
    # Accepted invites
    13.times do
      accepting_member = FactoryGirl.create(:member, :first_name => 'Accepting member')
      FactoryGirl.create(:sent_invite, :user => member, :invited_member => accepting_member, :accepted_at => accepted_at, :resubmitted => nil)
    end

    # Unaccepted invites
    7.times do
      FactoryGirl.create(:sent_invite, :user => member )
    end
  end
end
