require 'spec_helper'

describe Order do
  before do
    Resque.stub(:enqueue)
    Resque.stub(:enqueue_in)
  end

  subject { FactoryGirl.create(:clean_order)}
  let(:basic_shoe) { FactoryGirl.create(:basic_shoe) }
  let(:basic_shoe_35) { FactoryGirl.create(:basic_shoe_size_35, :product => basic_shoe) }
  let(:basic_shoe_37) { FactoryGirl.create(:basic_shoe_size_37, :product => basic_shoe) }
  let(:basic_shoe_40) { FactoryGirl.create(:basic_shoe_size_40, :product => basic_shoe) }
  let(:quantity) { 3 }
  let(:credits) { 1.89 }


  it { should have_one(:used_coupon) }

  context "coupons" do
    it "should decrement a standart coupon" do
      remaining_amount = 10
      order = FactoryGirl.create(:order)
      coupon = FactoryGirl.create(:standard_coupon, :remaining_amount => remaining_amount)
      order.create_used_coupon(:coupon => coupon)
      order.invalidate_coupon
      coupon.reload.remaining_amount.should == remaining_amount - 1
    end

    it "should increment a standart coupon" do
      remaining_amount = 10
      order = FactoryGirl.create(:order)
      coupon = FactoryGirl.create(:standard_coupon, :remaining_amount => remaining_amount)
      order.create_used_coupon(:coupon => coupon)
      order.use_coupon
      coupon.reload.used_amount.should == 1
    end

    it "should not decrement a unlimited coupon" do
      order = FactoryGirl.create(:order)
      coupon = FactoryGirl.create(:unlimited_coupon)
      order.create_used_coupon(:coupon => coupon)
      remaining_amount = coupon.remaining_amount
      order.invalidate_coupon
      coupon.reload.remaining_amount.should == remaining_amount
    end

    it "should increment a unlimited coupon" do
      order = FactoryGirl.create(:order)
      coupon = FactoryGirl.create(:unlimited_coupon)
      order.create_used_coupon(:coupon => coupon)
      remaining_amount = coupon.remaining_amount
      order.use_coupon
      coupon.reload.used_amount.should == 1
    end
  end

  context "creating a Order" do
    it "should generate a number" do
      order = FactoryGirl.create(:order)
      expected = (order.id * Order::CONSTANT_FACTOR) + Order::CONSTANT_NUMBER
      order.number.should == expected
    end

    it "should generate a identification code" do
      order = FactoryGirl.create(:order)
      order.identification_code.should_not be_nil
    end
  end

  context "line items with gifts" do
    before :each do
      subject.add_variant(basic_shoe_35)
      subject.add_variant(basic_shoe_37)
      subject.add_variant(basic_shoe_40)
    end

    it "#has_one_item_flagged_as_gift?" do
      subject.line_items_with_flagged_gift
      subject.line_items.reload
      subject.has_one_item_flagged_as_gift?.should be_true
    end

    it "#line_items_with_flagged_gift" do
      subject.should_receive(:clear_gift_in_line_items)
      subject.should_receive(:flag_second_line_item_as_gift)
      subject.line_items_with_flagged_gift
    end

    it "#clear_gift_in_line_items" do
      subject.line_items.first.update_attributes(:gift => true)
      subject.clear_gift_in_line_items
      subject.line_items.select{|item| item.gift?}.size.should == 0
    end
  end

  context "destroying a Order" do
    before :each do
      subject.add_variant(basic_shoe_35)
      subject.add_variant(basic_shoe_40)
    end

    it "should destroy the order" do
      expect {
        subject.destroy
      }.to change(Order, :count).by(-1)
    end

    it "should destroy line items" do
      expect {
        subject.destroy
      }.to change(LineItem, :count).by(-2)
    end
  end

  context "removing a variant" do
    before :each do
      subject.add_variant(basic_shoe_35)
    end

    describe "with a valid variant" do
      it "should destroy the variant line item" do
        expect {
          subject.remove_variant(basic_shoe_35)
        }.to change(LineItem, :count).by(-1)
      end
    end

    describe "with a invalid variant" do
      it "should not destroy the variant line item" do
        expect {
          subject.remove_variant(basic_shoe_40)
        }.to change(LineItem, :count).by(0)
      end

      it "should return a nil item" do
        subject.remove_variant(basic_shoe_40).should be(nil)
      end
    end
  end

  context 'in a order with items' do
    let(:items_total) { basic_shoe_35.price + (quantity * basic_shoe_40.price) }
    before :each do
      subject.add_variant(basic_shoe_35)
      subject.add_variant(basic_shoe_40, quantity)
    end

    describe '#line_items_total' do
      it 'should calculate the total' do
        expected = items_total
        subject.line_items_total.should == expected
      end
    end

    describe "#total_discount" do
      it "should return all discounts" do
        subject.stub(:credits).and_return(credits = 9.09)
        #subject.stub(:discount_from_gift).and_return(gift = 9.09)
        subject.stub(:discount_from_coupon).and_return(coupon = 8.36)
        subject.total_discount.should == credits + coupon
      end
    end

    describe "#discount_from_coupon" do
      context "with a used_coupon" do
        it "should return the value in Reais" do
          coupon = FactoryGirl.create(:standard_coupon)
          subject.create_used_coupon(:coupon => coupon)
          subject.discount_from_coupon.should == coupon.value
        end

        it "should return the value in Percentage" do
          coupon = FactoryGirl.create(:percentage_coupon)
          subject.create_used_coupon(:coupon => coupon)
          percent_value = (coupon.value * subject.line_items_total) / 100
          subject.discount_from_coupon.should == percent_value
        end
      end

      context "without a used_coupon" do
        it "should return 0" do
          subject.discount_from_coupon.should == 0
        end
      end
    end

    describe "#total" do
      context "without coupon" do
        it "should return the total discounting the credits" do
          credits = 11.09
          expected = items_total
          subject.stub(:credits).and_return(credits)
          subject.total.should == expected - credits
        end

        it "should return the total without discounting credits if it doesn't have any" do
          expected = items_total
          subject.total.should == expected
        end
      end

      context "with a coupon" do
        it "should return the total discounting the credits and coupons" do
          credits = 11.09
          coupon = FactoryGirl.create(:standard_coupon)
          subject.create_used_coupon(:coupon => coupon)
          expected = items_total - credits - coupon.value
          subject.stub(:credits).and_return(credits)
          subject.total.should == expected
        end
      end
    end

    describe '#total_with_freight' do
      it "should return the total with freight" do
        subject.stub(:credits).and_return(11.0)
        subject.stub(:freight_price).and_return(22.0)
        expected = items_total - 11.0 + 22.0
        subject.total_with_freight.should be_within(0.001).of(expected)
      end

      it "should return the same value as #total if there's no freight" do
        subject.stub(:credits).and_return(11.0)
        subject.stub(:freight_price).and_return(0)
        subject.total_with_freight.should be_within(0.001).of(items_total - 11)
      end
    end
  end

  context "in an order without items" do
    it "#line_items_total should be zero" do
      subject.line_items_total.should == 0
    end
    it "#total should be zero" do
      subject.total.should == Payment::MINIMUM_VALUE
    end
    it "#total_with_freight should be the value of the freight" do
      subject.total_with_freight.should == subject.freight.price + Payment::MINIMUM_VALUE
    end
  end

  context "when the inventory is not available" do
    before :each do
      basic_shoe_35.update_attributes(:inventory => 10)
    end

    it "should not create line items" do
      expect {
        subject.add_variant(basic_shoe_35, 11)
      }.to change(LineItem, :count).by(0)
    end

    it "should return a nil line item" do
      subject.add_variant(basic_shoe_35, 11).should == nil
    end
  end

  context "when the inventory is available" do
    before :each do
      basic_shoe_35.update_attributes(:inventory => 10)
    end

    it "should create line items" do
      expect {
        subject.add_variant(basic_shoe_35, 10)
      }.to change(LineItem, :count).by(1)
    end

    it "should not return a nil line item" do
      subject.add_variant(basic_shoe_35, 10).should_not == nil
    end
  end

  context "items availables in the order" do
    before :each do
      basic_shoe_35.update_attributes(:inventory => 10)
      subject.add_variant(basic_shoe_35, 2)

      basic_shoe_40.update_attributes(:inventory => 10)
      subject.add_variant(basic_shoe_40, 5)
    end

    context "when all variants are available" do
      it "should return 0 for #remove_unavailable_items" do
        subject.remove_unavailable_items.should == 0
      end

      it "should has 2 line items" do
        subject.remove_unavailable_items
        subject.line_items.count.should == 2
      end
    end

    context "when at least one variant is unavailable" do
      it "should return 1 for #remove_unavailable_items" do
        basic_shoe_40.update_attributes(:inventory => 3)
        subject.remove_unavailable_items
        subject.remove_unavailable_items.should == 1
      end

      it "should has just 1 line item" do
        basic_shoe_40.update_attributes(:inventory => 3)
        subject.remove_unavailable_items
        subject.line_items.count.should == 1
      end
    end
  end

  context "when the user try add a new variant" do
    it "should add it in the order" do
      expect {
        subject.add_variant(basic_shoe_35)
      }.to change(LineItem, :count).by(1)
    end

    it "should return a line item" do
      subject.add_variant(basic_shoe_35).should be_a(LineItem)
    end
  end

  context "when the variant already exists in the order" do
    before :each do
      subject.add_variant(basic_shoe_35)
      @line_item = subject.line_items.first
    end

    it "should update the quantity" do
      first_quantity = @line_item.quantity
      subject.add_variant(basic_shoe_35, quantity)
      @line_item.quantity.should == quantity
    end

    it "should not create line items" do
      expect {
        subject.add_variant(basic_shoe_35)
      }.to change(LineItem, :count).by(0)
    end
  end

  context "inventory update" do
    it "should decrement the inventory for each item" do
      basic_shoe_35_inventory = basic_shoe_35.inventory
      basic_shoe_40_inventory = basic_shoe_40.inventory
      subject.add_variant(basic_shoe_35, quantity)
      subject.add_variant(basic_shoe_40, quantity)
      subject.decrement_inventory_for_each_item
      basic_shoe_35.reload.inventory.should == basic_shoe_35_inventory - quantity
      basic_shoe_40.reload.inventory.should == basic_shoe_40_inventory - quantity
    end

    it "should increment the inventory for each item" do
      basic_shoe_35.increment!(:inventory, quantity)
      basic_shoe_40.increment!(:inventory, quantity)
      basic_shoe_35_inventory = basic_shoe_35.inventory
      basic_shoe_40_inventory = basic_shoe_40.inventory
      subject.add_variant(basic_shoe_35, quantity)
      subject.add_variant(basic_shoe_40, quantity)
      subject.increment_inventory_for_each_item
      basic_shoe_35.reload.inventory.should == basic_shoe_35_inventory + quantity
      basic_shoe_40.reload.inventory.should == basic_shoe_40_inventory + quantity
    end
  end

  describe '#installments' do
    context "when there's no payment" do
      it "should return 1" do
        subject.stub(:payment).and_return(nil)
        subject.installments.should == 1
      end
    end
    context "when there's a payment" do
      it "should return the number of installments of the payment" do
        subject.payment.stub(:payments).and_return(3)
        subject.installments.should == 3
      end
    end
  end

  describe "State machine transitions" do
    context "when the order is waiting payment" do
      it "should enqueue a job to insert a order" do
        Resque.should_receive(:enqueue).with(Abacos::InsertOrder, subject.number)
        subject.waiting_payment
      end

      it "should enqueue a Orders::NotificationOrderRequestedWorker" do
        subject.should_receive(:send_notification_order_requested)
        subject.waiting_payment
      end
    end

    context "when the order is authorized" do
      it "should enqueue a job to confirm a payment" do
        Resque.stub(:enqueue)
        Resque.should_receive(:enqueue_in).with(15.minutes, Abacos::ConfirmPayment, subject.number)
        subject.waiting_payment
        subject.authorized
      end

      it "should send a notification for payment confirmed" do
        subject.should_receive(:send_notification_payment_confirmed)
        subject.waiting_payment
        subject.authorized
      end
    end

    context "when the order is shipped" do
      it "should send a notification for payment shipped" do
        subject.should_receive(:send_notification_order_shipped)
        subject.waiting_payment
        subject.authorized
        subject.picking
        subject.delivering
      end
    end

    context "when the order is delivered" do
      it "should send a notification for payment delivered" do
        subject.should_receive(:send_notification_order_delivered)
        subject.waiting_payment
        subject.authorized
        subject.picking
        subject.delivering
        subject.delivered
      end
    end

    context "when the order is refused" do
      it "should send a notification for payment canceled" do
        subject.should_receive(:send_notification_payment_refused)
        subject.waiting_payment
        subject.canceled
      end

      it "should send a notification for payment refused" do
        subject.should_receive(:send_notification_payment_refused)
        subject.waiting_payment
        subject.authorized
        subject.under_review
        subject.reversed
      end
    end
  end

  describe "Notifications mailer" do
    it "should enqueue a Orders::NotificationOrderDeliveredWorker" do
      Resque.should_receive(:enqueue).with(Orders::NotificationOrderDeliveredWorker, subject.id)
      subject.send_notification_order_delivered
    end

    it "should enqueue a Orders::NotificationOrderShippedWorker" do
      Resque.should_receive(:enqueue).with(Orders::NotificationOrderShippedWorker, subject.id)
      subject.send_notification_order_shipped
    end

    it "should enqueue a Orders::NotificationPaymentConfirmedWorker" do
      Resque.should_receive(:enqueue).with(Orders::NotificationPaymentConfirmedWorker, subject.id)
      subject.send_notification_payment_confirmed
    end

    it "should enqueue a Orders::NotificationOrderRequestedWorker" do
      Resque.should_receive(:enqueue).with(Orders::NotificationOrderRequestedWorker, subject.id)
      subject.send_notification_order_requested
    end

    it "should enqueue a Orders::NotificationPaymentRefusedWorker" do
      Resque.should_receive(:enqueue).with(Orders::NotificationPaymentRefusedWorker, subject.id)
      subject.send_notification_payment_refused
    end
  end

  describe "State machine" do
    it "should has in_the_cart as initial state" do
      subject.in_the_cart?.should be_true
    end

    it "should set authorized" do
      subject.waiting_payment
      subject.authorized
      subject.authorized?.should be_true
    end

    it "should set authorized" do
      subject.waiting_payment
      subject.authorized
      subject.under_review
      subject.under_review?.should be_true
    end

    it "should set canceled" do
      subject.waiting_payment
      subject.canceled
      subject.canceled?.should be_true
    end

    it "should set canceled given not_delivered" do
      subject.waiting_payment
      subject.authorized
      subject.picking
      subject.delivering
      subject.not_delivered
      subject.canceled
      subject.canceled?.should be_true
    end

    it "should set canceled given in_the_cart" do
      subject.canceled
      subject.canceled?.should be_true
    end

    it "should set reversed" do
      subject.waiting_payment
      subject.authorized
      subject.under_review
      subject.reversed
      subject.reversed?.should be_true
    end

    it "should set refunded" do
      subject.waiting_payment
      subject.authorized
      subject.under_review
      subject.refunded
      subject.refunded?.should be_true
    end

    it "should set picking" do
      subject.waiting_payment
      subject.authorized
      subject.picking
      subject.picking?.should be_true
    end

    it "should set delivering" do
      subject.waiting_payment
      subject.authorized
      subject.picking
      subject.delivering
      subject.delivering?.should be_true
    end

    it "should set delivered" do
      subject.waiting_payment
      subject.authorized
      subject.picking
      subject.delivering
      subject.delivered
      subject.delivered?.should be_true
    end

    it "should set not_delivered" do
      subject.waiting_payment
      subject.authorized
      subject.picking
      subject.delivering
      subject.not_delivered
      subject.not_delivered?.should be_true
    end

    it "should enqueue a OrderStatusWorker in any transation with a payment" do
      Resque.should_receive(:enqueue).with(OrderStatusWorker, subject.id)
      subject.waiting_payment
    end

    it "should enqueue a OrderStatusWorker in any transation with a payment" do
      Resque.should_receive(:enqueue).with(OrderStatusWorker, subject.id)
      subject.waiting_payment
      subject.authorized
    end

    it "should use coupon when autorized" do
      subject.should_receive(:use_coupon)
      subject.waiting_payment
      subject.authorized
    end
  end

  describe "Order#status" do
    it "should return the status" do
      subject.status.should eq(Order::STATUS[subject.state])
    end
  end

  describe '#with_payment' do
    let!(:order_with_payment) { FactoryGirl.create :order }
    let!(:order_without_payment) do
      order = FactoryGirl.create :clean_order
      order.payment.destroy
      order
    end

    it 'should include the order with the payment' do
      described_class.with_payment.all.should include(order_with_payment)
    end
    it 'should not include the order without the payment' do
      described_class.with_payment.all.should_not include(order_without_payment)
    end
  end

  describe "delivery time" do
    it "should return the delivery time minus the time that the order is on warehouse" do
      freight = FactoryGirl.create(:freight, :order => subject)
      subject.delivery_time_for_a_shipped_order.should == freight.delivery_time - Order::WAREHOUSE_TIME
    end
  end

  describe "Audit trail" do
    it "should audit the transition" do
      subject.waiting_payment
      subject.authorized
      transition = subject.order_state_transitions.last
      transition.event.should == "authorized"
      transition.from.should == "waiting_payment"
      transition.to.should == "authorized"
    end
  end
end
