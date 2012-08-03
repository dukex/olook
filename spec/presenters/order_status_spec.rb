# -*- encoding : utf-8 -*-
require "spec_helper"

describe OrderStatus do
  let(:order) {  FactoryGirl.create(:order) }
  subject { OrderStatus.new(order) }

  before :each do
    Resque.stub(:enqueue)
    Resque.stub(:enqueue_in)
  end

  context "order.requested?" do
    it "should return status date for order-requested when waiting_payment" do
      subject.status.css_class.should == OrderStatus::STATUS["order-requested"][0]
      subject.status.message.should   == OrderStatus::STATUS["order-requested"][1]
    end

    it "should return status date for order-requested when under_review" do
      order.authorized
      order.under_review
      subject.status.css_class.should == OrderStatus::STATUS["order-requested"][0]
      subject.status.message.should   == OrderStatus::STATUS["order-requested"][1]
    end
  end

  context "order.canceled?" do
    it "should return status date for payment-made-denied" do
      order.canceled
      subject.status.css_class.should == OrderStatus::STATUS["payment-made-denied"][0]
      subject.status.message.should   == OrderStatus::STATUS["payment-made-denied"][1]
    end
  end

  context "order.reversed?" do
    it "should return status data for payment-made-failed" do
      order.authorized
      order.under_review
      order.reversed
      subject.status.css_class.should == OrderStatus::STATUS["payment-made-failed"][0]
      subject.status.message.should   == OrderStatus::STATUS["payment-made-failed"][1]
    end
  end

  context "order.refunded?" do
    it "should return status data for payment-made-failed" do
      order.authorized
      order.under_review
      order.refunded
      subject.status.css_class.should == OrderStatus::STATUS["payment-made-failed"][0]
      subject.status.message.should   == OrderStatus::STATUS["payment-made-failed"][1]
    end
  end

  context "order.authorized?" do
    it "should return status data for payment-made-authorized" do
      order.authorized
      subject.status.css_class.should == OrderStatus::STATUS["payment-made-authorized"][0]
      subject.status.message.should   == OrderStatus::STATUS["payment-made-authorized"][1]
    end
  end

  context "order.picking?" do
    it "should return status data for order-picking" do
      order.authorized
      order.picking
      subject.status.css_class.should == OrderStatus::STATUS["order-picking"][0]
      subject.status.message.should   == OrderStatus::STATUS["order-picking"][1]
    end
  end

  context "order.delivering?" do
    it "should return status data for order-delivering" do
      order.authorized
      order.picking
      order.delivering
      subject.status.css_class.should == OrderStatus::STATUS["order-delivering"][0]
      subject.status.message.should   == OrderStatus::STATUS["order-delivering"][1]
    end
  end
  context "order.not_delivered?" do
    it "should return status data for not-order-delivered" do
      order.authorized
      order.picking
      order.delivering
      order.not_delivered
      subject.status.css_class.should == OrderStatus::STATUS["order-not-delivered"][0]
      subject.status.message.should   == OrderStatus::STATUS["order-not-delivered"][1]
    end
  end

  context "order.delivered?" do
    it "should return status data for order-delivered" do
      order.authorized
      order.picking
      order.delivering
      order.delivered
      subject.status.css_class.should == OrderStatus::STATUS["order-delivered"][0]
      subject.status.message.should   == OrderStatus::STATUS["order-delivered"][1]
    end
  end
end
