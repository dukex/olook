# -*- encoding : utf-8 -*-
require 'spec_helper'

describe CartController do
  with_a_logged_user do
    render_views
    let(:variant) { FactoryGirl.create(:basic_shoe_size_35) }
    let(:product) { variant.product }

    describe "GET show" do
      it "should assign @bonus" do
        get :show
        assigns(:bonus).should == InviteBonus.calculate(user)
      end
    end

    describe "GET show" do
      it "should assign @bonus" do
        bonus_value = '12.34'
        put :update_bonus, :credits => {:value => bonus_value}
        session[:order].credits.to_f.should == bonus_value.to_f
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

        it "should redirect to cart_path" do
          Order.any_instance.stub(:remove_variant).with(variant).and_return(true)
          put :update, :variant => {:id => variant.id}
          response.should redirect_to cart_path, :notice => "Este produto não está na sua sacola"
        end
      end

      describe "with a invalid variant" do
        it "should redirect to root_path" do
          Order.any_instance.stub(:remove_variant).with(variant).and_return(false)
          put :update, :variant => {:id => variant.id}
          response.should redirect_to cart_path, :notice => "Este produto não está na sua sacola"
        end
      end
    end

    describe "POST create" do
      before :each do
        @back = request.env['HTTP_REFERER'] = product_path(product)
      end

      context "with a valid @variant" do
        it "should create a Order" do
          expect {
            post :create, :variant => {:id => variant.id}
          }.to change(Order, :count).by(1)
        end

        it "should assign a order in the session" do
          post :create, :variant => {:id => variant.id}
          session[:order].should == Order.last
        end

        it "should not create a Order when already exists in the session" do
          post :create, :variant => {:id => variant.id}
          expect {
            post :create, :variant => {:id => variant.id}
          }.to change(Order, :count).by(0)
        end

        it "should redirect back to product page" do
          post :create, :variant => {:id => variant.id}
          response.should redirect_to(product_path(product))
        end

        it "should add a variant in the order" do
          Order.any_instance.should_receive(:add_variant).with(variant).and_return(true)
          post :create, :variant => {:id => variant.id}
        end
      end

      context "with a invalid @variant" do
        it "should redirect back with a warning if the variant dont exists" do
          post :create, :variant => {:id => ""}
          response.should redirect_to(@back, :notice => "Selecione um produto")
        end

        it "should redirect back with a warning if the variant is not available" do
          Variant.any_instance.stub(:available?).and_return(false)
          post :create, :variant => {:id => ""}
          response.should redirect_to(@back, :notice => "Produto esgotado")
        end
      end
    end
  end
end

