require "spec_helper"

describe PaymentBuilder do

  let(:user) { FactoryGirl.create(:user) }
  let(:order) { FactoryGirl.create(:order, :user => user) }
  let(:credit_card) { FactoryGirl.create(:credit_card, :order => order) }
  let(:billet) { FactoryGirl.create(:billet, :order => order) }
  let(:debit) { FactoryGirl.create(:debit, :order => order) }

  let(:address) { FactoryGirl.create(:address, :user => user) }
  let(:cart) { FactoryGirl.create(:cart_with_items, :user => user) }
  let(:shipping_service) { FactoryGirl.create :shipping_service }
  let(:freight) { { :price => 12.34, :cost => 2.34, :delivery_time => 2, :shipping_service_id => shipping_service.id, :address_id => address.id} }
  let(:cart_service) { CartService.new({
    :cart => cart,
    :freight => freight,
  }) }

  subject {
    pb = PaymentBuilder.new(cart_service, credit_card)
    pb.credit_card_number = credit_card.credit_card_number
    pb
  }
  let(:payer) { subject.payer }

  let(:order_total) { 12.34 }

  before :each do
    Airbrake.stub(:notify)
    # order.stub(:total).and_return(10.50)
    # @order_total = order.amount_paid
  end

  it "should verify if MoIP uri was properly initialized" do
    moip_uri = MoIP.uri
    moip_uri.should be_true
  end

  it "should verify if MoIP token was properly initialized" do
    moip_token = MoIP.token
    moip_token.should be_true
  end

  it "should verify if MoIP key was properly initialized" do
    moip_key = MoIP.key
    moip_key.should be_true
  end

  context "on success" do
    it "should process the payment" do
      pending "REVIEW THIS"
      subject.should_receive(:send_payment!)
      payment = double(Payment)
      subject.should_receive(:set_payment_url!).and_return(payment)
      subject.process!
    end

    context "success actions" do
      before :each do
        subject.stub(:send_payment!)
        subject.payment.stub(:build_response)
        subject.payment.stub(:gateway_response_status).and_return(Payment::SUCCESSFUL_STATUS)
        subject.payment.stub(:gateway_transaction_status).and_return(:success)
        subject.stub(:set_payment_url!).and_return(subject.payment)
      end

      it "should set payment order" do
        pending "REVIEW THIS"
        subject.set_payment_order!
        subject.payment.order.should == order
      end

      it "should decrement the inventory for each item" do
        pending "REVIEW THIS"
        basic_shoe_35_inventory = basic_shoe_35.inventory
        basic_shoe_40_inventory = basic_shoe_40.inventory
        subject.line_items.create(
          :variant_id => basic_shoe_35.id,
          :quantity => quantity,
          :price => basic_shoe_35.price,
          :retail_price => basic_shoe_35.retail_price)
        subject.line_items.create(
          :variant_id => basic_shoe_40.id,
          :quantity => quantity,
          :price => basic_shoe_40.price,
          :retail_price => basic_shoe_40.retail_price)
        subject.decrement_inventory_for_each_item
        basic_shoe_35.reload.inventory.should == basic_shoe_35_inventory - quantity
        basic_shoe_40.reload.inventory.should == basic_shoe_40_inventory - quantity
      end

      it "should create a coupon when used" do
        pending "REVIEW THIS"
        expect {
          cart_service = CartService.new({:cart => cart, :freight => freight, :coupon => coupon_of_value})
          cart_service.stub(:total_coupon_discount => 100)
          order = cart_service.generate_order!
          order.used_coupon.coupon.should be(coupon_of_value)
        }.to change{Order.count}.by(1)
      end

      it "should return a structure with status and a payment" do
        response = subject.process!
        response.status.should == Payment::SUCCESSFUL_STATUS
        response.payment.should == credit_card
      end

      it "should invalidate the order coupon" do
        pending "REVIEW THIS"
        Coupon.any_instance.should_receive(:decrement!)
        subject.process!
      end

      it "should create a promotion when used" do
        pending "REVIEW THIS"
        expect {
          cart_service = CartService.new({:cart => cart, :freight => freight, :promotion => promotion})

          cart_service.stub(:total_discount_by_type => 20)

          order = cart_service.generate_order!

          order.used_promotion.promotion.should be(promotion)
          order.used_promotion.discount_percent.should be(promotion.discount_percent)
          order.used_promotion.discount_value.should eq(20)

        }.to change{Order.count}.by(1)
      end
    end
  end

  context "on failure" do
    before :each do
      subject.stub(:send_payment!)
    end

    it "should return a structure with failure status and without a payment when the gateway comunication fail " do
      subject.payment.stub(:gateway_response_status).and_return(Payment::FAILURE_STATUS)
      subject.stub_chain(:set_payment_url!).and_return(subject.payment)
      subject.process!.status.should == Payment::FAILURE_STATUS
      subject.process!.payment.should be_nil
    end

    it "should return a structure with failure status and without a payment" do
      subject.payment.stub(:gateway_response_status).and_return(Payment::SUCCESSFUL_STATUS)
      subject.payment.stub(:gateway_transaction_status).and_return(Payment::CANCELED_STATUS)
      subject.stub_chain(:set_payment_url!).and_return(subject.payment)
      subject.process!.status.should == Payment::FAILURE_STATUS
      subject.process!.payment.should be_nil
    end

    it "should return a structure with failure status and without a payment" do
      subject.stub(:send_payment!).and_raise(Exception)
      subject.process!.status.should == Payment::FAILURE_STATUS
      subject.process!.payment.should be_nil
    end
  end

  it "should set payment url" do
    subject.stub(:payment_url).and_return('www.fake.com')
    subject.set_payment_url!
    subject.payment.url.should == 'www.fake.com'
  end

  it "should send payments" do
    MoIP::Client.should_receive(:checkout).with(subject.payment_data)
    subject.send_payment!
  end

  it "should get the payment_url" do
    subject.response = {"Token" => "XCV"}
    MoIP::Client.should_receive(:moip_page).with(subject.response["Token"])
    subject.payment_url
  end

  it "should return the payer" do
    delivery_address = order.freight.address
    expected = {
      :nome => user.name,
      :email => user.email,
      :identidade => credit_card.user_identification,
      :logradouro => delivery_address.street,
      :complemento => delivery_address.complement,
      :numero => delivery_address.number,
      :bairro => delivery_address.neighborhood,
      :cidade => delivery_address.city,
      :estado => delivery_address.state,
      :pais => delivery_address.country,
      :cep => delivery_address.zip_code,
      :tel_fixo => delivery_address.telephone,
      :tel_cel => delivery_address.mobile
    }

    subject.payer.should == expected
  end

  it "should return payment data for billet" do
    subject.payment = billet
    expected_expiration_date = billet.payment_expiration_date.strftime("%Y-%m-%dT15:00:00.0-03:00")
    expected = { :valor => order_total, :id_proprio => billet.identification_code,
                :forma => subject.payment.to_s, :recebimento => billet.receipt, :pagador => payer,
                :razao=> Payment::REASON, :data_vencimento => expected_expiration_date }

    subject.payment_data.should == expected
  end

  it "should return payment data for debit" do
    subject.payment = debit
    expected = { :valor => order_total, :id_proprio => debit.identification_code, :forma => subject.payment.to_s,
               :instituicao => debit.bank, :recebimento => debit.receipt, :pagador => payer,
               :razao => Payment::REASON }

    subject.payment_data.should == expected
  end

  it "should return payment data for credit card" do
    subject.payment = credit_card
    payer = subject.payer
    expected = { :valor => order_total, :id_proprio => credit_card.identification_code, :forma => subject.payment.to_s,
              :instituicao => credit_card.bank, :numero => credit_card.credit_card_number,
              :expiracao => credit_card.expiration_date, :codigo_seguranca => credit_card.security_code,
              :nome => credit_card.user_name, :identidade => credit_card.user_identification,
              :telefone => credit_card.telephone, :data_nascimento => credit_card.user_birthday,
              :parcelas => credit_card.payments, :recebimento => credit_card.receipt,
              :pagador => payer, :razao => Payment::REASON }

    subject.payment_data.should == expected
  end
 end
