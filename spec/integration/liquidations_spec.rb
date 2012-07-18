 # -*- encoding : utf-8 -*-
require 'spec_helper'
require 'integration/helpers'

feature "Liquidation", %q{
  In order to buy products with discounts
  As a user
  I want to see the liquidation products
  } do

  let!(:user) { FactoryGirl.create(:user) }
  let(:basic_shoe_size_35) { FactoryGirl.create(:basic_shoe_size_35) }
  let(:liquidation) { FactoryGirl.create(:liquidation) }

  describe "Liquidation" do
    background do
      do_login!(user)
    end

    scenario "User can see the liquidation" do
      visit liquidations_path(liquidation)
      page.should have_content(liquidation.name)
    end

    scenario "User can search usign some filters" do
      LiquidationProduct.create(
        :liquidation => liquidation,
        :product_id => basic_shoe_size_35.product.id,
        :subcategory_name => "rasteira",
        :subcategory_name_label => "Rasteira",
        :inventory => 1
      )
      visit liquidations_path(liquidation)

      #TODO FIX THIS
      # check("rasteira")
      # save_and_open_page
      page.should have_content(basic_shoe_size_35.product.name)
    end
    
    scenario "User can see the liquidation even withouth products" do
      liquidation1 = FactoryGirl.create(:liquidation, :resume => nil)
      visit liquidations_path(liquidation1)
      current_path.should == "/membro/vitrine"
      page.should have_content("A liquidação não possui produtos")
    end
  end
end
