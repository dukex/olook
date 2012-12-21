# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'integration/helpers'

feature "Buying products", %q{
  In order to buy products
  As a user
  I want to build a look
} do

  let(:user) { FactoryGirl.create(:user) }
  let!(:user_info) { FactoryGirl.create(:user_info, user: user, shoes_size: nil) }
  let(:product) { FactoryGirl.create :basic_shoe }
  let!(:loyalty_program_credit_type) { FactoryGirl.create(:loyalty_program_credit_type, :code => :loyalty_program) }
  let!(:invite_credit_type) { FactoryGirl.create(:invite_credit_type, :code => :invite) }
  let!(:redeem_credit_type) { FactoryGirl.create(:redeem_credit_type, :code => :redeem) }

  context "buying products" do
    background do
      FacebookAdapter.any_instance.stub(:facebook_friends_registered_at_olook).and_return([])
      do_login!(user)
      FactoryGirl.create(:main_picture, :product => product)
    end

    context "in the products page" do
      scenario "I want to see product" do
        visit product_path(product)
        page.should have_content(product.name)
      end
      scenario "I want to have my shoe size already selected" do
        visit product_path(product)
        within("ol") do
          page.should have_xpath("//a[@class='selected']")
        end
      end
    end

    context "with the shopping cart" do
      context "and the product is a shoe" do
        let(:shoe) { FactoryGirl.create :basic_shoe }
        let!(:shoe_a) { FactoryGirl.create(:basic_shoe_size_35, :product => shoe) }
        let!(:shoe_b) { FactoryGirl.create(:basic_shoe_size_40, :product => shoe) }

        background do
          FactoryGirl.create(:main_picture, :product => shoe)
        end

        scenario "I need to choose the variant and then add it to the cart" do

          # Checkout::CartController.any_instance.stub(:find_suggested_product).and_return(nil)
          ids = Setting.recommended_products.split(",").map {|product_id| product_id.to_i} 
          Product.stub(:find).with(ids).and_return(nil)

          visit product_path(shoe)
          choose shoe_a.number
          click_button "add_product"
          page.should have_content("Produto adicionado com sucesso")
        end
        scenario "If I don't choose a variant and try to add it to the cart, it should tell me I need to pick a size" do
          visit product_path(shoe)
          click_button "add_product"
          page.should have_content("Produto não disponível para esta quantidade ou inexistente")
        end
      end

      context "and the product is a bag" do
        let!(:bag) { FactoryGirl.create(:basic_bag) }
        let!(:bag_a) { FactoryGirl.create(:variant, :product => bag, :inventory => 10) }
        let!(:bag_b) { FactoryGirl.create(:variant, :product => bag, :inventory => 10) }

        background do
          FactoryGirl.create(:main_picture, :product => bag)
        end

        scenario "just need to click 'add to the cart'" do
          ids = Setting.recommended_products.split(",").map {|product_id| product_id.to_i} 
          Product.stub(:find).with(ids).and_return(nil)

          visit product_path(bag)
          click_button "add_product"
          page.should have_content("Produto adicionado com sucesso")
        end
      end

      context "and the product is an accessory" do
        let!(:accessory) { FactoryGirl.create(:basic_accessory) }
        let!(:accessory_a) { FactoryGirl.create(:variant, :product => accessory, :inventory => 10) }

        background do
          FactoryGirl.create(:main_picture, :product => accessory)
        end

        scenario "just need to click 'add to the cart'" do
          ids = Setting.recommended_products.split(",").map {|product_id| product_id.to_i} 
          Product.stub(:find).with(ids).and_return(nil)
          
          visit product_path(accessory)
          click_button "add_product"
          page.should have_content("Produto adicionado com sucesso")
        end
      end
    end
  end
end
