 # -*- encoding : utf-8 -*-
require 'spec_helper'
require 'integration/helpers'

feature "Buying Gifts", %q{
  In order to buy a gift for a special person
  As a user
  I want to be able to choose and buy the correct product
  } do

  let!(:user) { FactoryGirl.create(:user) }
  let!(:occasion_type) { FactoryGirl.create(:gift_occasion_type) }
  let!(:recipient_relation) { FactoryGirl.create(:gift_recipient_relation) }
  let!(:gift_survey) { FactoryGirl.create(:gift_question) }
  let!(:loyalty_program_credit_type) { FactoryGirl.create(:loyalty_program_credit_type, :code => :loyalty_program) }
  let!(:invite_credit_type) { FactoryGirl.create(:invite_credit_type, :code => :invite) }
  let!(:redeem_credit_type) { FactoryGirl.create(:redeem_credit_type, :code => :redeem) }
  let!(:gift_box_helena) { FactoryGirl.create(:gift_box_helena) }
  let!(:gift_box_top_five) { FactoryGirl.create(:gift_box_top_five) }
  let!(:gift_box_hot_fb) { FactoryGirl.create(:gift_box_hot_fb) }

  describe "Already user" do
    background do
      do_login!(user)
    end

    scenario "visiting the gift project landing page/home" do
      visit gift_root_path
      page.should have_content("Acerte em cheio no presente")
    end

    describe "going through all gift process" do
      before :each do
        pending
        visit gift_root_path
        click_link "new_occasion_link"
      end

      scenario "starting the process of creating a gift" do
        pending
        page.should have_content("Estou escolhendo um presente")
      end

      scenario "filling data and being redirect to quiz page" do
        pending
        fill_in 'recipient_name', :with => 'Jonh Doe'
        select occasion_type.name, :from => 'occasion_gift_occasion_type_id'
        select recipient_relation.name, :from => 'recipient_gift_recipient_relation_id'
        click_button "continuar"
        page.should have_content( gift_survey.title )
      end

      scenario "answering the quiz for my recipient" do
      end

    end

    scenario "viewing my recipient profile and choosing her shoe size" do
    end

    scenario "choosing some products for my recipient" do
    end

    scenario "checking out" do
    end

    describe "with facebook" do
      scenario "create gift for a facebook friend" do
      end
    end

    describe "log to facebook" do
    end
  end

  describe "logged out" do
    scenario "should see the landing page with disabled calendar" do
      pending
      visit gift_root_path
      page.should have_content("Acerte em cheio no presente")
      page.has_css?('.opacity')
    end

    scenario "should start the gift creation" do
      pending
      visit gift_root_path
      click_link "new_occasion_link"
      page.should have_content("Estou escolhendo um presente")
    end

    scenario "should see the suggestions for a gift recipient" do
    end
  end
end

