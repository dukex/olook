# -*- encoding : utf-8 -*-
require 'spec_helper'

describe PaymentsController do
  let(:user) { FactoryGirl.create(:user) }
  let(:address) { FactoryGirl.create(:address, :user => user) }
  let(:order) { FactoryGirl.create(:order, :user => user) }
  let(:payment) { FactoryGirl.create(:billet, :order => order) }
  let(:total) { 99.55 }
  let(:billet_printed) { "3" }
  let(:cod_moip) { "3" }
  let(:tipo_pagamento) { "CartaoDeCredito" }
  let(:params) {{:status_pagamento => billet_printed, :id_transacao => order.identification_code, :value => total, :cod_moip => cod_moip, :tipo_pagamento => tipo_pagamento}}

  before :each do

    Resque.stub(:enqueue)
    Resque.stub(:enqueue_in)
    Airbrake.stub(:notify)
    FactoryGirl.create(:line_item, :order => Order.find(order))
    request.env['devise.mapping'] = Devise.mappings[:user]
    order.waiting_payment

    sign_in user
  end

  describe "GET index" do
    before :each do
      session[:order] = order
    end

    context "with a valid order" do
      it "should be success" do
        get 'index'
        response.should be_successful
      end
    end

    context "with a invalid order" do
      it "should redirect to root path if the order is nil" do
        session[:order] = nil
        get 'index'
        response.should redirect_to(cart_path)
      end

      it "should redirect to cart path if the order total_with_freight is less then 5.00" do
        Order.any_instance.stub(:line_items).and_return([])
        get 'index'
        response.should redirect_to(cart_path)
      end
    end

    context "with a valid freight" do
      it "should assign @freight" do
        get 'index'
        assigns(:freight).should == order.freight
      end

      it "should assign @cart" do
        session[:order] = order
        Cart.should_receive(:new).with(order)
        get 'index'
      end
    end

    context "with a invalid freight" do
      it "assign redirect to address_path" do
        Order.find(order).freight.destroy
        get 'index'
        response.should redirect_to(addresses_path)
      end
    end
  end

  describe "GET show" do
    it "should assigns @payment" do
      get :show, :id => payment.id
      assigns(:payment).should == payment
    end
  end

  describe "POST create" do
    before :each do
      sign_out user
    end

    context "with valids params" do
      it "should return 200" do
        post :create, params
        response.status.should == 200
      end

      it "should change the payment status to billet_printed" do
        post :create, params
        order.payment.reload.billet_printed?.should eq(true)
      end

      it "should update payment with the params" do
        post :create, params
        order.payment.reload.gateway_code.should == cod_moip
        order.payment.reload.gateway_status.to_s.should == billet_printed
        order.payment.reload.gateway_type.should == tipo_pagamento
      end

      it "should change the order status to authorized" do
        billet_printed = "3"
        post :create, :status_pagamento => billet_printed, :id_transacao => order.identification_code, :value => total
        authorized = "1"
        post :create, :status_pagamento => authorized, :id_transacao => order.identification_code, :value => total
        Order.find(order.id).authorized?.should eq(true)
      end

      it "should change not the order status after receiving completed" do
        billet_printed = "3"
        post :create, :status_pagamento => billet_printed, :id_transacao => order.identification_code, :value => total
        authorized = "1"
        post :create, :status_pagamento => authorized, :id_transacao => order.identification_code, :value => total
        completed = "4"
        post :create, :status_pagamento => completed, :id_transacao => order.identification_code, :value => total
        Order.find(order.id).authorized?.should eq(true)
      end

      it "should create a MoipCallback" do
        expect {
        post :create, :status_pagamento => billet_printed,
                      :id_transacao => order.identification_code, :tipo_pagamento => tipo_pagamento, :cod_moip => cod_moip
        }.to change(MoipCallback, :count).by(1)
      end

    end

    context "with invalids params" do
      it "should return 500 with a invalid status" do
        invalid_status = "0"
        post :create, :status_pagamento => invalid_status, :id_transacao => order.identification_code, :value => total
        response.status.should == 500
      end
    end
  end
end
