# -*- encoding : utf-8 -*-
require "spec_helper"

describe Billet do

  let(:order) { FactoryGirl.create(:order) }
  subject { FactoryGirl.create(:billet, :order => order) }
  let(:billet_printed) { "3" }
  let(:authorized) { "1" }
  let(:completed) { "4" }
  let(:under_review) { "8" }

  before :each do
    Resque.stub(:enqueue)
    Resque.stub(:enqueue_in)
    order.waiting_payment
  end

  context "expiration date" do
    subject { FactoryGirl.create(:billet) }

    context "expired" do
      before :each do
        subject.stub(:payment_expiration_date).and_return(Date.civil(2012, 2, 6))
      end

      it "should to be expired for 2012, 2, 9" do
        Date.stub(:current).and_return(Date.civil(2012, 2, 9))
        subject.expired?.should be_true
      end

      it "should to be expired for 2012, 2, 10" do
        Date.stub(:current).and_return(Date.civil(2012, 2, 10))
        subject.expired?.should be_true
      end

      it "should to be expired for 2012, 2, 10" do
        subject.stub(:payment_expiration_date).and_return(Date.civil(2012, 2, 10))
        Date.stub(:current).and_return(Date.civil(2012, 2, 16))
        subject.expired?.should be_true
      end
    end

    context "not expired" do
      before :each do
        subject.stub(:payment_expiration_date).and_return(Date.civil(2012, 2, 6))
      end

      it "should not to be expired for 2012, 2, 5" do
        Date.stub(:current).and_return(Date.civil(2012, 2, 5))
        subject.expired?.should be_false
      end

      it "should not to be expired for 2012, 2, 6" do
        Date.stub(:current).and_return(Date.civil(2012, 2, 6))
        subject.expired?.should be_false
      end

      it "should not to be expired for 2012, 2, 7" do
        Date.stub(:current).and_return(Date.civil(2012, 2, 7))
        subject.expired?.should be_false
      end

      it "should not to be expired for 2012, 2, 8" do
        Date.stub(:current).and_return(Date.civil(2012, 2, 8))
        subject.expired?.should be_false
      end

      it "should not to be expired for 2012, 2, 14" do
        subject.stub(:payment_expiration_date).and_return(Date.civil(2012, 2, 10))
        Date.stub(:current).and_return(Date.civil(2012, 2, 14))
        subject.expired?.should be_false
      end
    end
  end

  context "payment expiration date" do
    it "should set payment expiration date after create" do
      BilletExpirationDate.stub(:expiration_for_two_business_day).and_return(current_date = Date.current)
      billet = FactoryGirl.create(:billet)
      billet.payment_expiration_date.to_date.should == BilletExpirationDate.expiration_for_two_business_day
    end
  end

  it "should return to_s version" do
    subject.to_s.should == "BoletoBancario"
  end

  it "should return human to_s human version" do
    subject.human_to_s.should == "Boleto Bancário"
  end

  context "attributes validation" do
    subject { Billet.new }
    it{ should validate_presence_of :receipt }
  end

  context "status" do
    it "should return nil with a invalid status" do
      invalid_status = '0'
      subject.set_state(invalid_status).should be(nil)
    end
  end

  describe "order state machine" do
    it "should set canceled for order when started" do
      subject.canceled
      subject.order.canceled?.should eq(true)
    end

    it "should set canceled for order when billet_printed" do
      subject.billet_printed
      subject.canceled
      subject.order.canceled?.should eq(true)
    end

    it "should set authorized for order" do
      subject.billet_printed
      subject.authorized
      subject.order.authorized?.should eq(true)
    end

    it "should not change the order status from authorized when the payment is completed" do
      subject.billet_printed
      subject.authorized
      subject.completed
      subject.order.authorized?.should eq(true)
    end

    it "should not change the order status from under review when the payment is completed after under review" do
      subject.billet_printed
      subject.authorized
      subject.under_review
      subject.completed
      subject.order.under_review?.should eq(true)
    end

    it "should set under_review for order" do
      subject.billet_printed
      subject.authorized
      subject.under_review
      subject.order.under_review?.should eq(true)
    end

   it "should set refunded for order" do
      subject.billet_printed
      subject.authorized
      subject.under_review
      subject.refunded
      subject.order.refunded?.should eq(true)
    end
  end

  describe "state machine" do
    it "should set canceled given started" do
      subject.canceled
      subject.canceled?.should eq(true)
    end

    it "should set canceled given billet_printed" do
      subject.billet_printed
      subject.canceled
      subject.canceled?.should eq(true)
    end

    it "should set billet_printed" do
      subject.set_state(billet_printed)
      subject.billet_printed?.should eq(true)
    end

    it "should set authorized" do
      subject.set_state(billet_printed)
      subject.set_state(authorized)
      subject.authorized?.should eq(true)
    end

    it "should set completed" do
      subject.set_state(billet_printed)
      subject.set_state(authorized)
      subject.set_state(completed)
      subject.completed?.should eq(true)
    end

    it "should set under_review" do
      subject.set_state(billet_printed)
      subject.set_state(authorized)
      subject.set_state(under_review)
      subject.under_review?.should eq(true)
    end

    it "should set completed given under_review" do
      subject.set_state(billet_printed)
      subject.set_state(authorized)
      subject.set_state(under_review)
      subject.set_state(completed)
      subject.completed?.should eq(true)
    end
  end
end
