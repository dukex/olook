# -*- encoding : utf-8 -*-
require 'spec_helper'

describe DebitsController do
  let(:attributes) {{"bank"=>"BancoDoBrasil", "receipt" => Payment::RECEIPT}}
  let(:user) { FactoryGirl.create(:user) }
  let(:address) { FactoryGirl.create(:address, :user => user) }
  let(:order) { FactoryGirl.create(:order, :user => user).id }

  before :each do
    user.update_attributes(:cpf => "19762003691")
    FactoryGirl.create(:line_item, :order => Order.find(order))
    request.env['devise.mapping'] = Devise.mappings[:user]
    sign_in user
  end

  describe "GET new" do
    before :each do
      session[:order] = order
    end

    context "with a valid order" do
     it "should assigns @payment" do
        get 'new'
        assigns(:payment).should be_a_new(Debit)
      end

      it "should redirect payments_path if the user dont have a cpf or is invalid" do
        user.update_attributes(:cpf => "12345678912")
        get :new
        response.should redirect_to(payments_path)
      end

      it "should not redirect payments_path if the user have a cpf" do
        get :new
        response.should_not redirect_to(payments_path)
      end
    end

    context "with a invalid order" do
      it "should redirect to cart path if the order is nil" do
        session[:order] = nil
        get 'new'
        response.should redirect_to(cart_path)
      end

      it "should redirect to cart path if the order dont have line items" do
        Order.any_instance.stub(:line_items).and_return([])
        get 'new'
        response.should redirect_to(cart_path)
      end
    end

    context "with a valid freight" do
      it "should assign @freight" do
        get 'new'
        assigns(:freight).should == Order.find(order).freight
      end

      it "should assign @cart" do
        Cart.should_receive(:new).with(Order.find(order))
        get 'new'
      end
    end

    context "with a invalid freight" do
      it "assign redirect to address_path" do
        Order.find(order).freight.destroy
        get 'new'
        response.should redirect_to(addresses_path)
      end
    end
  end

  describe "POST create" do
    before :each do
      session[:order] = order
      @order = Order.find(order)
      @processed_payment = OpenStruct.new(:status => Payment::SUCCESSFUL_STATUS, :payment => mock_model(Debit))
    end

    describe "with some variant unavailable" do
      it "redirect to cath path" do
        PaymentBuilder.should_receive(:new).and_return(payment_builder = mock)
        payment_builder.stub(:process!).and_return(OpenStruct.new(:status => Product::UNAVAILABLE_ITEMS, :payment => nil))
        post :create, :debit => attributes
        response.should redirect_to(cart_path)
      end
    end

    describe "with valid params" do
      it "should process the payment" do
        PaymentBuilder.stub(:new).and_return(payment_builder = mock)
        payment_builder.should_receive(:process!).and_return(@processed_payment)
        post :create, :debit => attributes
      end

      it "should clean the session order" do
        PaymentBuilder.stub(:new).and_return(payment_builder = mock)
        payment_builder.should_receive(:process!).and_return(@processed_payment)
        post :create, :debit => attributes
        session[:order].should be_nil
        session[:freight].should be_nil
        session[:delivery_address_id].should be_nil
      end

      it "should redirect to order_debit_path" do
        PaymentBuilder.stub(:new).and_return(payment_builder = mock)
        payment_builder.should_receive(:process!).and_return(debit = @processed_payment)
        post :create, :debit => attributes
        response.should redirect_to(order_debit_path(:number => @order.number))
      end

      it "should assign @cart" do
        PaymentBuilder.stub(:new).and_return(payment_builder = mock)
        payment_builder.should_receive(:process!).and_return(debit = @processed_payment)
        Cart.should_receive(:new).with(Order.find(order))
        post :create, :debit => attributes
      end
    end

    describe "with invalid params" do
      before :each do
        processed_payment = OpenStruct.new(:status => Payment::FAILURE_STATUS, :payment => mock_model(Debit))
        payment_builder = mock
        payment_builder.stub(:process!).and_return(processed_payment)
        PaymentBuilder.stub(:new).and_return(payment_builder)
      end

      it "should render new" do
        post :create
        response.should render_template("new")
      end
    end
  end
end
