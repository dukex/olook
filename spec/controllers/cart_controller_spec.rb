# -*- encoding : utf-8 -*-
require 'spec_helper'

describe CartController do
  with_a_logged_user do
    render_views
    let(:variant) { FactoryGirl.create(:basic_shoe_size_35) }
    let(:product) { variant.product }
    let(:order) { FactoryGirl.create(:order, :user => user) }
    let(:quantity) { 3 }

    describe "GET show" do
      it "should assign @bonus" do
        session[:order] = order.id
        get :show
        assigns(:bonus).should == InviteBonus.calculate(user)
      end

      it "GET show with token and order_id" do
        get :show, :auth_token => 'RandomToken', :order_id => order.id
        assigns(:order).should == order
      end
    end

    describe "DELETE remove_coupon" do
      before :each do
        session[:order] = order
      end

      it "should apply the coupon" do
        CouponManager.should_receive(:new).with(order).and_return(coupon_manager = mock)
        coupon_manager.should_receive(:remove_coupon)
        delete :remove_coupon
      end

      it "should redirect to cart_path" do
        CouponManager.should_receive(:new).with(order).and_return(coupon_manager = mock)
        coupon_manager.should_receive(:remove_coupon).and_return(msg = :success)
        delete :remove_coupon
        response.should redirect_to(cart_path)
        flash[:notice].should eq(msg)
      end
    end

    describe "PUT update_coupon" do
      before :each do
        session[:order] = order
      end

      it "should apply the coupon" do
        code = "abc"
        CouponManager.should_receive(:new).with(order, code).and_return(coupon_manager = mock)
        coupon_manager.should_receive(:apply_coupon)
        put :update_coupon, :coupon => {:code => code}
      end

      it "should redirect to cart_path" do
        code = "abc"
        CouponManager.stub(:new).and_return(coupon_manager = double)
        coupon_manager.stub(:apply_coupon).and_return(msg = :success)
        put :update_coupon, :coupon => {:code => code}
        response.should redirect_to(cart_path)
        flash[:notice].should eq(msg)
      end
    end

    describe "DELETE remove_bonus" do
      context "when the user is using credits bonus" do
        it "should sert order credits to nil" do
          session[:order] = order
          Order.any_instance.stub(:credits).and_return(1)
          Order.any_instance.should_receive(:update_attributes).with(:credits => nil)
          delete :remove_bonus
          response.should redirect_to cart_path
        end
      end

      context "when the user is not using credits bonus" do
        it "should not set order credits to nil" do
          session[:order] = order
          Order.any_instance.stub(:credits).and_return(0)
          Order.any_instance.should_not_receive(:update_attributes).with(:credits => nil)
          delete :remove_bonus
          response.should redirect_to cart_path
        end
      end
    end

    describe "PUT update_bonus" do
      context "when the user has bonus" do
        before :each do
          InviteBonus.stub(:calculate).and_return(100)
        end

        it "should update the order with a new bonus value" do
          session[:order] = order
          bonus_value = '12.34'
          Order.any_instance.should_receive(:update_attributes).with(:credits => bonus_value)
          put :update_bonus, :credits => {:value => bonus_value}
        end

        it "should update the order with a new bonus value" do
          bonus_value = '12.34'
          FactoryGirl.create(:freight, :order => order)
          session[:order] = order.id
          post :create, :variant => {:id => variant.id}
          expect {
            put :update_bonus, :credits => {:value => bonus_value}
          }.to change(Freight, :count).by(-1)
        end

        it "should redirect to card_path" do
          bonus_value = '12.34'
          put :update_bonus, :credits => {:value => bonus_value}
          response.should redirect_to(cart_path)
        end

        it "should format credits value to use dots" do
          bonus_value = '12,34'
          put :update_bonus, :credits => {:value => "12.34"}
          response.should redirect_to(cart_path)
        end
      end

      context "when the user dont have bonus enougth" do
        it "should not update the order" do
          bonus_value = '12.34'
          Order.any_instance.should_not_receive(:update_attributes).with(:credits => bonus_value)
          put :update_bonus, :credits => {:value => bonus_value}
        end
      end
    end

    describe "DELETE destroy" do
      it "should destroy the order in the session" do
        delete :destroy
        session[:order].should be(nil)
      end

      it "should redirect to cart_path" do
        delete :destroy
        response.should redirect_to(cart_path)
      end

      it "should destroy the Order" do
        post :create, :variant => {:id => variant.id}
        expect {
          delete :destroy
        }.to change(Order, :count).by(-1)
      end
    end

    describe "PUT update" do
      describe "with a valid variant" do
        it "should delete a item from the cart" do
          Order.any_instance.should_receive(:remove_variant).with(variant).and_return(true)
          put :update, :variant => {:id => variant.id}
        end

        it "should delete a item from the cart" do
          FactoryGirl.create(:freight, :order => order)
          session[:order] = order.id
          post :create, :variant => {:id => variant.id}
          expect {
            put :update, :variant => {:id => variant.id}
          }.to change(Freight, :count).by(-1)
        end

        it "should redirect to cart_path" do
          Order.any_instance.stub(:remove_variant).with(variant).and_return(true)
          put :update, :variant => {:id => variant.id}
          response.should redirect_to cart_path
          flash[:notice].should eq("Produto removido com sucesso")
        end

        it "should delete the order when the last item is removed" do
          post :create, :variant => {:id => variant.id}
          expect {
            put :update, :variant => {:id => variant.id}
          }.to change(Order, :count).by(-1)
        end
      end

      describe "with a invalid variant" do
        it "should redirect to root_path" do
          Order.any_instance.stub(:remove_variant).with(variant).and_return(false)
          put :update, :variant => {:id => variant.id}
          response.should redirect_to cart_path
          flash[:notice].should eq("Este produto não está na sua sacola")
        end
      end
    end

    describe "PUT update_quantity_product" do
      before :each do
        @back = request.env['HTTP_REFERER'] = product_path(product)
      end

      context "with a valid @variant" do
        it "should redirect back to product page" do
          put :update_quantity_product, :variant => {:id => variant.id, :quantity => quantity}
          response.should redirect_to(cart_path)
        end

        it "should destroy order freight" do
          FactoryGirl.create(:freight, :order => order)
          session[:order] = order.id
          post :create, :variant => {:id => variant.id}
          expect {
            put :update_quantity_product, :variant => {:id => variant.id, :quantity => quantity}
          }.to change(Freight, :count).by(-1)
        end

        it "should update the variant quantity in the order" do
          Order.any_instance.should_receive(:add_variant).with(variant, quantity.to_s).and_return(true)
          put :update_quantity_product, :variant => {:id => variant.id, :quantity => quantity}
        end
      end

      context "with a invalid @variant" do
        it "should redirect back with a warning if the variant dont exists" do
          put :update_quantity_product, :variant => {:id => "", :quantity => quantity}
          response.should redirect_to(@back)
        end

        it "should redirect back with a warning if the variant is not available" do
          variant.update_attributes(:inventory => 0)
          post :create, :variant => {:id => variant.id}
          response.should redirect_to(@back)
          flash[:notice].should eq("Produto não disponível para esta quantidade ou inexistente")
        end
      end
    end

    describe "POST create" do
      before :each do
        @back = request.env['HTTP_REFERER'] = product_path(product)
      end

      context "with a valid @variant" do
        it "should create a Order" do
          FactoryGirl.create(:freight, :order => order)
          session[:order] = order.id
          expect {
            post :create, :variant => {:id => variant.id}
          }.to change(Freight, :count).by(-1)
        end

        it "should create a Order" do
          expect {
            post :create, :variant => {:id => variant.id}
          }.to change(Order, :count).by(1)
        end

        it "should assign a order in the session" do
          post :create, :variant => {:id => variant.id}
          Order.find(session[:order]).should == Order.last
        end

        it "should not create a Order when already exists in the session" do
          post :create, :variant => {:id => variant.id}
          expect {
            post :create, :variant => {:id => variant.id}
          }.to change(Order, :count).by(0)
        end

        it "should redirect cart_path" do
          post :create, :variant => {:id => variant.id}
          response.should redirect_to(cart_path)
        end

        it "should add a variant in the order" do
          Order.any_instance.should_receive(:add_variant).with(variant).and_return(true)
          post :create, :variant => {:id => variant.id}
        end
      end

      context "with a invalid @variant" do
        it "should redirect back with a warning if the variant dont exists" do
          post :create, :variant => {:id => ""}
          response.should redirect_to(@back)
          flash[:notice].should eq("Produto não disponível para esta quantidade ou inexistente")
        end

        it "should redirect back with a warning if the variant is not available" do
          variant.update_attributes(:inventory => 0)
          post :create, :variant => {:id => variant.id}
          response.should redirect_to(@back)
          flash[:notice].should eq("Produto não disponível para esta quantidade ou inexistente")
        end
      end
    end
  end
end

