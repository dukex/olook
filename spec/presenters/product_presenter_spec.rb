# -*- encoding : utf-8 -*-
require "spec_helper"

describe ProductPresenter do
  include ActionView::TestCase::Behavior
  let(:product) { FactoryGirl.create :basic_shoe }
  let(:member) { double :user }
  let(:facebook_app_id) { double :facebook_app_id }
  let(:template) { double :template }
  subject { described_class.new template, :product => product, :member => member, :facebook_app_id => facebook_app_id, :shoe_size => 35, :only_view? => false }
  let(:only_view) { described_class.new template, :product => product, :member => member, :facebook_app_id => facebook_app_id, :shoe_size => 35, :only_view? => true }

  describe "user showroom methods" do
    describe '#render_member_showroom' do
      it "should render the partial with the carousel with the member's showroom" do
        template.should_receive(:render).with(:partial => 'product/member_showroom', :locals => {:product_presenter => subject}).and_return('showroom')
        subject.render_member_showroom.should == 'showroom'
      end
    end

    describe '#collection_name' do
      context "when there is an active collection" do
        let!(:collection) { FactoryGirl.create :collection }

        it 'returns the name of the active collection' do
          Collection.should_receive(:active).and_return(collection)
          subject.collection_name.should == collection.name
        end
      end

      context "when there is no active collection" do
        it 'returns the current month name' do
          Date.stub_chain(:today).and_return(Date.new(2011,04,03))
          subject.collection_name.should == 'Abril'
        end
      end
    end

    describe "#render_main_profile_showroom" do
      it "should render a list of product images with links to their pages" do
        products = [:product_a, :product_b]
        subject.member.should_receive(:main_profile_showroom).and_return(products)
        template.should_receive(:render).with(:partial => 'shared/showroom_product_item', :collection => products, :as => :product)
        subject.render_main_profile_showroom
      end
    end
  end

  describe '#render_related_products' do
    it "should render the partial with product's related products" do
      subject.stub(:related_products).and_return(:mock_related_products)
      template.should_receive(:render).with(:partial => 'product/related_products', :locals => {:related_products => :mock_related_products}).and_return('related')
      subject.render_related_products.should == 'related'
    end
  end

  describe '#render_description' do
    it "should render the partial with the product's description" do
      template.should_receive(:render).with(:partial => 'product/description', :locals => {:product_presenter => subject}).and_return('description')
      subject.render_description.should == 'description'
    end
  end

  describe '#render_add_to_cart' do
    let(:online) { described_class.new template, :product => product, :member => member, :facebook_app_id => facebook_app_id, :logged? => true, :gift? => false, :only_view? => false }
    let(:online_gift) { described_class.new template, :product => product, :member => member, :facebook_app_id => facebook_app_id, :logged? => true, :gift? => true, :only_view? => false }
    let(:offline) { described_class.new template, :product => product, :member => member, :facebook_app_id => facebook_app_id, :logged? => false, :gift? => false, :only_view? => false }
    let(:offline_gift) { described_class.new template, :product => product, :member => member, :facebook_app_id => facebook_app_id, :logged? => false, :gift? => true, :only_view? => false }

    it "should return empty when is only view" do
      only_view.render_add_to_cart.should == ''
    end

    context "when is gift" do
      it "and user is offline should render the partial with controls to add the product to gift_list" do
        template.should_receive(:render).with(:partial => 'product/add_to_suggestions', :locals => {:product_presenter => offline_gift, :product => product}).and_return('gift list')
        offline_gift.render_add_to_cart.should == 'gift list'
      end

      it "and user is online should render the partial with controls to add the product to gift_list" do
        template.should_receive(:render).with(:partial => 'product/add_to_suggestions', :locals => {:product_presenter => online_gift, :product => product}).and_return('gift list')
        online_gift.render_add_to_cart.should == 'gift list'
      end
    end

    it "should render the partial with controls to add the product to the cart when online" do
      template.should_receive(:render).with(:partial => 'product/add_to_cart', :locals => {:product_presenter => online, :product => product}).and_return('cart')
      online.render_add_to_cart.should == 'cart'
    end
  end

  describe '#render_form_by_category' do
    it 'should render the group box with color and size for shoes' do
      subject.product.stub(:category).and_return(Category::SHOE)
      template.should_receive(:render).with(:partial => 'product/form_for_shoe', :locals => {:product_presenter => subject}).and_return('shoe_form')
      subject.render_form_by_category.should == 'shoe_form'
    end
    it 'should render the group box with color and a hidden field with the variant for bags' do
      subject.product.stub(:category).and_return(Category::BAG)
      template.should_receive(:render).with(:partial => 'product/form_for_bag', :locals => {:product_presenter => subject}).and_return('shoe_form')
      subject.render_form_by_category.should == 'shoe_form'
    end
    it 'should render just the hidden field with the variant for accessories' do
      subject.product.stub(:category).and_return(Category::ACCESSORY)
      template.should_receive(:render).with(:partial => 'product/form_for_accessory', :locals => {:product_presenter => subject}).and_return('shoe_form')
      subject.render_form_by_category.should == 'shoe_form'
    end
  end

  describe '#render_details' do
    it "should render the partial with the product details" do
      template.should_receive(:render).with(:partial => 'product/details', :locals => {:product_presenter => subject}).and_return('details')
      subject.render_details.should == 'details'
    end
  end

  describe '#render_colors' do
    it "should return empty when is only view" do
      only_view.render_colors.should == ''
    end

    it "should render the partial with the product colors" do
      template.should_receive(:render).with(:partial => 'product/colors',  :locals => {:product => subject.product, :gift => true, :shoe_size => 35}).and_return('colors')
      subject.render_colors.should == 'colors'
    end
  end

  describe '#render_facebook_comments' do
    it "should render the partial with the product colors" do
      template.should_receive(:render).with(:partial => 'product/facebook_comments',  :locals => {:product => subject.product, :facebook_app_id => subject.facebook_app_id}).and_return('facebook_comments')
      subject.render_facebook_comments.should == 'facebook_comments'
    end
  end

  describe '#render_single_size' do
    before :each do
      subject.product.stub_chain(:variants, :sorted_by_description).and_return([:single_variant])
    end
    it 'should render just a hidden field with the variant' do
      template.should_receive(:render).with(:partial => 'product/single_size', :locals => {:variant => :single_variant})
      subject.render_single_size
    end
  end

  describe '#render_multiple_sizes' do
    let(:sizes) { [:size_one, :size_two] }
    before :each do
      subject.product.stub_chain(:variants, :sorted_by_description).and_return(sizes)
    end
    it 'should render all variants to select' do
      template.should_receive(:render).with(:partial => 'product/sizes', :locals => {:variants => sizes, :shoe_size => 35})
      subject.render_multiple_sizes
    end
  end

  describe '#related_products' do
    context "when the product doesn't have any related products" do
      it "should return an empty array" do
        subject.related_products.should be_empty
      end
    end

    context "when the product has some related products " do
      let(:related_shoe)      { FactoryGirl.create(:basic_shoe) }
      let(:related_bag)       { FactoryGirl.create(:basic_bag) }
      let(:out_of_stock_bag)  { FactoryGirl.create(:basic_bag) }

      let!(:v_related_shoe)      { FactoryGirl.create(:basic_shoe_size_35, :product => related_shoe) }
      let!(:v_related_bag)       { FactoryGirl.create(:variant, :product => related_bag, :inventory => 10) }
      let!(:v_out_of_stock_bag)  { FactoryGirl.create(:variant, :product => out_of_stock_bag) }

      it "should return an empty array if all of them are of the same category as the presented product" do
        product.relate_with_product related_shoe
        subject.related_products.should == []
      end

      it "should only included products in stock" do
        product.relate_with_product out_of_stock_bag
        subject.related_products.should == []
      end

      it "should only the related products of a different category from the presented product" do
        product.relate_with_product related_shoe
        product.relate_with_product related_bag
        subject.related_products.should == [related_bag]
      end
    end
  end

  describe "#price" do
    subject { described_class.new view, :product => product, :member => member, :facebook_app_id => facebook_app_id }
    let(:guest) { described_class.new view, :product => product, :member => nil, :facebook_app_id => facebook_app_id }
    let!(:promotion) { FactoryGirl.create(:first_time_buyers) }

    it "should render the price when no discount" do
      pending "REVIEW THIS"
    end

    it "should render the price with markdown when for first time buyers" do
      pending "REVIEW THIS"
      member.stub(:first_time_buyer?).and_return(true)
      subject.render_price.should include("de:")
      subject.render_price.should include("por:")
      subject.render_price.should include("em sua primeira compra")
    end

    it "should render the price with markdown when discount is detected" do
      product.stub(:retail_price).and_return(49.99)
      member.stub(:first_time_buyer?).and_return(false)
      subject.render_price.should include("de:")
      subject.render_price.should include("por:")
      subject.render_price.should_not include("em sua primeira compra")
    end

    it "should show 20% off for guests" do
      product.stub(:price).and_return(49.99)
      product.stub(:retail_price).and_return((42.99))
      guest.render_price.should include("de:")
      guest.render_price.should include("por:")
      guest.render_price.should include("em sua primeira compra")
    end
  end

  context "#user_expiration_month" do
    let(:now) { DateTime.now }
    let(:user) { FactoryGirl.create(:user, created_at: now) }

    it "returns the expiration month for a given user formatted correctly" do
      month_str = "%02d" % (now + 7.days).to_date.month.to_s
      subject.user_expiration_month(user).should eq month_str
    end
  end

  context "#user_expiration_day" do
    let(:now) { DateTime.now }
    let(:user) { FactoryGirl.create(:user, created_at: now) }

    it "returns the expiration day for a given user formatted correctly" do
      day_str = "%02d" % (now + 7.days).to_date.day.to_s
      subject.user_expiration_day(user).should eq day_str
    end
  end  
end
