# -*- encoding : utf-8 -*-
require 'spec_helper'

describe BilletsController do
  let(:attributes) {{}}
  let(:user) { FactoryGirl.create(:user) }
  let(:address) { FactoryGirl.create(:address, :user => user) }
  let(:order) { FactoryGirl.create(:order, :user => user).id }

  before :each do
    user.update_attributes(:cpf => "19762003691")
    request.env['devise.mapping'] = Devise.mappings[:user]
    FactoryGirl.create(:line_item, :order => Order.find(order))
    sign_in user
  end

  describe "GET new" do
    before :each do
     session[:order] = order
    end

    context "with a valid order" do
      it "should assigns @payment" do
        get 'new'
        assigns(:payment).should be_a_new(Billet)
      end

      it "should redirect payments_path if the user dont have a cpf or is invalid" do
        user.update_attributes(:cpf => "11111111111")
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

      it "should redirect to cart path if the order total with freight is less then 5.00" do
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
        # CartPresenter.should_receive(:new).with(Order.find(order))
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
      @processed_payment = OpenStruct.new(:status => Payment::SUCCESSFUL_STATUS, :payment => mock_model(Billet))
    end

    describe "with some variant unavailable" do
      it "redirects to cath path" do
        PaymentBuilder.should_receive(:new).and_return(payment_builder = mock)
        payment_builder.stub(:process!).and_return(OpenStruct.new(:status => Product::UNAVAILABLE_ITEMS, :payment => nil))
        post :create, :billet => attributes
        response.should redirect_to(cart_path)
      end
    end

    describe "with valid params" do
      it "should process the payment" do
        PaymentBuilder.should_receive(:new).and_return(payment_builder = mock)
        payment_builder.should_receive(:process!).and_return(@processed_payment)
        post :create, :billet => attributes
      end

      it "should add the user for a campaing if requested" do
        PaymentBuilder.should_receive(:new).and_return(payment_builder = mock)
        payment_builder.should_receive(:process!).and_return(@processed_payment)
        expect {
          post :create, :billet => attributes , :campaing => {:sign_campaing => 'foobar'}
        }.to change(user.campaing_participants, :count).by(1)
      end

      it "should clean the session order" do
        PaymentBuilder.stub(:new).and_return(payment_builder = mock)
        payment_builder.should_receive(:process!).and_return(@processed_payment)
        post :create, :billet => attributes
        session[:order].should be_nil
        session[:freight].should be_nil
        session[:delivery_address_id].should be_nil
      end

      it "should redirect to order_billet_path" do
        PaymentBuilder.stub(:new).and_return(payment_builder = mock)
        payment_builder.should_receive(:process!).and_return(processed_payment = @processed_payment)
        post :create, :billet => attributes
        session.should redirect_to(order_billet_path(:number => @order.number))
      end

      it "should assign @cart" do
        # CartPresenter.should_receive(:new).with(Order.find(order))
        get 'new'
      end
    end

    describe "with invalid params" do
      before :each do
        processed_payment = OpenStruct.new(:status => Payment::FAILURE_STATUS, :payment => mock_model(Billet))
        payment_builder = mock
        payment_builder.stub(:process!).and_return(processed_payment)
        PaymentBuilder.stub(:new).and_return(payment_builder)
      end

      it "should render new template" do
        post :create, :billet => attributes
        response.should render_template('new')
      end
    end
  end
end
