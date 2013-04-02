# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Product do
  describe "validation" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:model_number) }
    it { should have_many(:pictures) }
    it { should have_many(:details) }
    it { should have_many(:variants) }
    it { should have_many(:catalog_products) }
    it { should have_many(:catalogs) }
    it { should belong_to(:collection) }
    it { should have_and_belong_to_many(:profiles) }

    it { should respond_to :backside_picture }
    it { should respond_to :wearing_picture }
    it { should respond_to :remove_freebie }
  end

  describe ".featured_products" do

    context "when there is no featured products configured" do
      before do
        Product.should_receive(:fetch_all_featured_products_of).with(Category::SHOE).and_return([])
      end

      it "return empty array" do
        Product.featured_products(Category::SHOE).should be_empty
      end
    end

    context "when there is two featured products configured" do
      before do
        featured_products = [
          mock_model(Product, inventory_without_hiting_the_database: 2),
          mock_model(Product, inventory_without_hiting_the_database: 1)
        ]

        Product.should_receive(:fetch_all_featured_products_of)
          .with(Category::SHOE)
          .and_return(featured_products)

        Product.any_instance.stub(:inventory_without_hiting_the_database).and_return(2)
      end

      it "return both products" do
        Product.featured_products(Category::SHOE).should have(2).items
      end


    end


  end

  describe "#add_freebie" do
    let(:product) { FactoryGirl.create :blue_sliper_with_variants }
    let(:bag) { FactoryGirl.create(:basic_bag_with_variant) }
    let(:shoe) { FactoryGirl.create(:shoe, :casual) }

    it { should respond_to :add_freebie }

    context "when adding a bag" do
      it "every variant should have a freebie" do
        FreebieVariant.should_receive(:create!).exactly(product.variants.size).times
        product.add_freebie bag
      end
    end

  end

  describe "scopes" do
    let!(:shoe)      { FactoryGirl.create(:shoe, :casual) }
    let!(:shoe_for_xml) { FactoryGirl.create :blue_sliper_with_variants }
    let!(:bag)       { FactoryGirl.create(:basic_bag) }
    let!(:accessory) { FactoryGirl.create(:basic_accessory) }
    let!(:invisible_shoe) { FactoryGirl.create(:shoe, :casual, :is_visible => false) }

    context ".shoes" do
      it "includes all shoes" do
        shoes = [shoe, invisible_shoe]
        (described_class.shoes & shoes).should == shoes
      end

      it "does not include other kinds of items" do
        other = [bag, accessory]
        (described_class.shoes & other).should be_empty
      end
    end

    context ".bags" do
      it "includes a bag" do
        described_class.bags.should include bag
      end

      it "does not include other kinds of items" do
        other = [shoe, invisible_shoe, accessory]
        (described_class.bags & other).should be_empty
      end
    end

    context ".acessories" do
      it "includes an accessory" do
        described_class.accessories.should include accessory
      end

      it "does not include other kinds of items" do
        other = [shoe, invisible_shoe, bag]
        (described_class.accessories & other).should be_empty
      end
    end

    context ".visible" do
      it "returns visible products" do
        visible_products = [shoe, bag, accessory]
        (described_class.only_visible & visible_products) =~ visible_products
      end

      it "does not return a invisible product" do
        described_class.accessories.should_not include invisible_shoe
      end
    end

    context "xml ouput" do

      describe ".valid_for_xml" do
        it "returns shoes with variants and doesn't return shoes without variants" do
          shoe_for_xml.master_variant.update_attribute(:price, 1.0)
          #about the factories: shoe_for_xml includes variants, shoe doesn't
          described_class.valid_for_xml([0],[0]).should include(shoe_for_xml)
          described_class.valid_for_xml([0],[0]).should_not include(shoe)
        end

        it "doesn't return shoes with less than 3 variants with 3 inventory each" do
          # leave only 3 variants on factory
          shoe_for_xml.variants.first.destroy
          # set inventory to less than 3 on each variant
          shoe_for_xml.variants.each {|v| v.update_attribute(:inventory, 2)}
          described_class.valid_for_xml([0],[0]).should_not include(shoe_for_xml)
        end

        it "returns shoes with 3 or more variants with 3 or more inventory each" do
          # leave only 3 variants on factory
          shoe_for_xml.variants.first.destroy
          shoe_for_xml.variants.each {|v| v.update_attribute(:inventory, 4)}
          described_class.valid_for_xml([0],[0]).should include(shoe_for_xml)
        end
      end

      describe ".valid_criteo_for_xml" do
        it "returns products valid for criteo" do
          products = [shoe, bag, accessory, shoe_for_xml]
          shoe_for_xml.master_variant.update_attribute(:price, 1.0)
          (described_class.valid_criteo_for_xml([0],[0]) & products).should == [shoe_for_xml]
        end

        it "doesn't return shoes with less than 3 variants with 3 inventory each" do
          # leave only 3 variants on factory
          shoe_for_xml.variants.first.destroy
          # set inventory to less than 3 on each variant
          shoe_for_xml.variants.each {|v| v.update_attribute(:inventory, 2)}
          described_class.valid_for_xml([0],[0]).should_not include(shoe_for_xml)
        end

        it "returns shoes with 3 or more variants with 3 or more inventory each" do
          # leave only 3 variants on factory
          shoe_for_xml.variants.first.destroy
          shoe_for_xml.variants.each {|v| v.update_attribute(:inventory, 4)}
          described_class.valid_for_xml([0],[0]).should include(shoe_for_xml)
        end
      end

      describe "blacklisted products" do
        before do
          shoe.master_variant.update_attribute(:price, 1.0)
        end
      end
    end
  end

  describe 'when working with related products' do
    subject { FactoryGirl.create(:red_slipper) }
    let(:silver_slipper) { FactoryGirl.create(:silver_slipper) }
    let(:unrelated_product) { FactoryGirl.create(:shoe, :casual) }

    it "#related_products" do
      FactoryGirl.create(:related_product, :product_a => silver_slipper, :product_b => subject )
      subject.related_products.should include(silver_slipper)
    end

    it "#unrelated_products" do
      related_product = FactoryGirl.create(:related_product, :product_a => silver_slipper, :product_b => subject)
      subject.unrelated_products.should include unrelated_product
      subject.unrelated_products.should_not include related_product
    end

    describe "#is_related_to?" do
      before :each do
        FactoryGirl.create(:related_product, :product_a => silver_slipper, :product_b => subject )
      end

      it "should return true when the relationship exists" do
        subject.is_related_to?(silver_slipper).should be_true
      end
      it "should return false when the relationship doesn't exists" do
        subject.is_related_to?(subject).should be_false
      end
    end

    it "#relate_with_product" do
      subject.relate_with_product(silver_slipper)
      subject.related_products.should include(silver_slipper)
    end
  end

  describe "#master_variant" do
    subject { FactoryGirl.build(:shoe, :casual) }

    it "newly initialized products should return nil" do
      subject.master_variant.should be_nil
    end

    it "should call create_master_variant after_saving a new product" do
      subject.should_receive(:create_master_variant)
      subject.save
    end

    it "should call update_master_variant after_saving a change in the product" do
      subject.save
      subject.price = 10
      subject.should_receive(:update_master_variant)
      subject.save
    end

    it "should be created automaticaly after the product is created" do
      subject.save
      subject.master_variant.should_not be_nil
      subject.master_variant.should be_persisted
      subject.master_variant.description.should == 'master'
    end

    describe 'helper methods' do
      it '#create_master_variant' do
        new_variant = double :variant
        new_variant.should_receive(:'save!')
        Variant.should_receive(:new).and_return(new_variant)
        subject.instance_variable_get('@master_variant').should be_nil
        subject.send :create_master_variant
        subject.instance_variable_get('@master_variant').should == new_variant
      end

      describe '#update_master_variant' do
        before :each do
          subject.save # create product
          subject.description = 'a'
        end

        it 'should trigger the method after_update' do
          subject.should_receive(:update_master_variant)
          subject.save
        end

        it 'should call save on the master variant' do
          subject.master_variant.should_receive(:'save!')
          subject.save
        end

        it 'fix bug: should not break if @master_variant was not initialized' do
          loaded_product = Product.find subject.id
          expect {
            loaded_product.save
          }.not_to raise_error
        end
      end
    end
  end

  describe "methods delegated to master_variant" do
    subject { FactoryGirl.create(:shoe, :casual) }

    describe 'getter methods' do
      it "#price" do
        subject.master_variant.should_receive(:price)
        subject.price
      end

      it "#retail_price" do
        subject.master_variant.should_receive(:retail_price)
        subject.retail_price
      end

      it "#discount_percent" do
        subject.master_variant.should_receive(:discount_percent)
        subject.discount_percent
      end

      it "#width" do
        subject.master_variant.should_receive(:width)
        subject.width
      end

      it "#height" do
        subject.master_variant.should_receive(:height)
        subject.height
      end

      it "#length" do
        subject.master_variant.should_receive(:length)
        subject.length
      end

      it "#weight" do
        subject.master_variant.should_receive(:weight)
        subject.weight
      end
    end

    describe 'setter methods' do
      it "#price=" do
        subject.price = 765.0
        subject.master_variant.price.should == 765.0
      end

      it "#retail_price=" do
        subject.retail_price = 99.0
        subject.master_variant.retail_price.should == 99.0
      end

      it "#discount_percent=" do
        subject.discount_percent = 99.0
        subject.master_variant.discount_percent.should == 99.0
      end

      it "#width=" do
        subject.width = 55.0
        subject.master_variant.width.should == 55.0
      end

      it "#height=" do
        subject.height = 66.0
        subject.master_variant.height.should == 66.0
      end

      it "#length=" do
        subject.length = 77.0
        subject.master_variant.length.should == 77.0
      end

      it "#weight=" do
        subject.weight = 987.0
        subject.master_variant.weight.should == 987.0
      end
    end
  end

  describe "picture helpers" do
    let(:mock_picture) { double :picture }

    describe '#main_picture' do
      let!(:some_picture) { FactoryGirl.create(:picture, :product => subject, :display_on => DisplayPictureOn::GALLERY_3) }
      let!(:main_picture) { FactoryGirl.create(:main_picture, :product => subject) }

      it 'should return the picture to be displayed as Gallery 1' do
        subject.main_picture.should == main_picture
      end
    end

    describe "#showroom_picture" do
      it "should return the showroom sized image if it exists" do
        mock_picture.stub(:image_url).with(:showroom).and_return(:valid_image)
        subject.stub(:main_picture).and_return(mock_picture)
        subject.showroom_picture.should == :valid_image
      end
      it "should return nil if it doesn't exist" do
        subject.showroom_picture.should be_nil
      end
    end

    describe '#thumb_picture' do
      it "should return the thumb sized image if it exists" do
        mock_picture.stub(:image_url).with(:thumb).and_return(:valid_image)
        subject.stub(:main_picture).and_return(mock_picture)
        subject.thumb_picture.should == :valid_image
      end
      it "should return nil if it doesn't exist" do
        subject.thumb_picture.should be_nil
      end
    end

    describe '#suggestion_picture' do
      it "should return the suggestion sized image if it exists" do
        mock_picture.stub(:image_url).with(:suggestion).and_return(:valid_image)
        subject.stub(:main_picture).and_return(mock_picture)
        subject.suggestion_picture.should == :valid_image
      end
      it "should return nil if it doesn't exist" do
        subject.suggestion_picture.should be_nil
      end
    end

    describe '#catalog_picture' do
      it "should return the picture sized image if it exists" do
        mock_picture.stub(:image_url).with(:catalog).and_return(:valid_image)
        mock_picture.stub(:display_on).and_return(1)
        subject.stub(:main_picture).and_return(mock_picture)
        subject.stub(:fetch_cache_for).and_return(:valid_image)
        subject.catalog_picture.should == :valid_image
      end
      it "should return nil if it doesn't exist" do
        subject.catalog_picture.should be_nil
      end
    end

    describe '#return_catalog_or_suggestion_image' do
      context "when product has picture" do
        before :each do
          mock_picture.stub(:image_url).with(:catalog).and_return(:valid_image)
          mock_picture.stub(:display_on).and_return(1)
          subject.stub(:main_picture).and_return(mock_picture)
        end

        it "returns catalog picture" do
          subject.stub(:fetch_cache_for).and_return(:valid_image)
          subject.return_catalog_or_suggestion_image(mock_picture).should eq(:valid_image)
        end

        it "returns suggestion picture" do
          mock_picture.stub(:image_url).with(:suggestion).and_return(:suggestion_image)
          subject.stub(:fetch_cache_for).and_return(:suggestion_image)
          subject.return_catalog_or_suggestion_image(mock_picture).should eq(:suggestion_image)
        end
      end

      context "when product has no picture" do
        it "returns nil" do
          mock_picture = nil
          subject.return_catalog_or_suggestion_image(mock_picture).should be_nil
        end
      end
    end

    describe '#image_at_position' do
      let!(:shoe)      { FactoryGirl.create(:shoe, :casual) }
      let!(:main_picture)      { FactoryGirl.create(:main_picture) }
      it 'should return the image at asked position' do
        shoe.pictures << main_picture

        picture = shoe.picture_at_position 1
        picture.should eq main_picture
      end

      it 'should return nil if there is no picture at desired position' do
        picture = shoe.picture_at_position 1
        picture.should be nil
      end

    end
  end

  describe '#variants.sorted_by_description' do
    subject { FactoryGirl.create(:shoe, :casual) }
    let!(:last_variant) { FactoryGirl.create(:variant, :product => subject, :description => '36') }
    let!(:first_variant) { FactoryGirl.create(:variant, :product => subject, :description => '35') }

    it 'should return the variants sorted by description' do
      subject.variants.should == [last_variant, first_variant]
      subject.variants.sorted_by_description.should == [first_variant, last_variant]
    end
  end

  context "color variations" do
    let(:black_shoe) { FactoryGirl.create(:shoe, :casual, :color_name => 'black', :color_sample => 'black_sample') }
    let(:red_shoe) { FactoryGirl.create(:shoe, :casual, :color_name => 'red', :color_sample => 'red_sample') }
    let(:black_bag) { FactoryGirl.create(:basic_bag) }

    before :each do
      black_shoe.relate_with_product black_bag
      black_shoe.relate_with_product red_shoe
    end

    describe '#colors' do
      it 'returns a list of related products of the same category of the product' do
        black_shoe.colors.should == [red_shoe]
      end
    end

    describe "#all_colors" do
      it "returns a list of related products of the same category including the current product and orderd by product id" do
        black_shoe.all_colors.should == [black_shoe, red_shoe]
      end
    end
  end

  describe "#easy_to_find_description" do
    subject { FactoryGirl.build(:basic_bag,
                                :model_number => 'M123',
                                :name         => 'Fake product',
                                :color_name   => 'Black') }

    it 'should return a string with the model_number, name, color and humanized category' do
      subject.easy_to_find_description.should == 'M123 - Fake product - Black - Bolsa'
    end
  end

  describe 'inventory related methods' do
    subject { FactoryGirl.create(:shoe, :casual) }
    let!(:basic_shoe_size_35) { FactoryGirl.create :basic_shoe_size_35, :product => subject }
    let!(:basic_shoe_size_40) { FactoryGirl.create :basic_shoe_size_40, :product => subject }

    describe '#inventory' do
      it "should return the sum of the variants inventory" do
        basic_shoe_size_35.update_attributes(:inventory => 3)
        basic_shoe_size_40.update_attributes(:inventory => 1)
        subject.inventory.should == 4
      end
    end

    describe '#sold_out?' do
      it "should return false if any of the variants is available" do
        subject.stub(:inventory).and_return(2)
        subject.should_not be_sold_out
      end
      it "should return true if none of the variants is available" do
        subject.stub(:inventory).and_return(0)
        subject.should be_sold_out
      end
    end
  end

  describe '#product_url' do
    subject { FactoryGirl.create(:shoe, :casual) }

    context "without params" do
      it "returns valid url with the product id" do
        subject.product_url.should == "http://www.olook.com.br/produto/#{subject.id}?utm_campaign=produtos&utm_content=#{subject.id}&utm_medium=vitrine"
      end
    end

    context "with params" do
      it "returns valid url with the product id" do
        subject.product_url(:utm_source => "criteo", :utm_campaign => "teste").should == "http://www.olook.com.br/produto/#{subject.id}?utm_campaign=teste&utm_content=#{subject.id}&utm_medium=vitrine&utm_source=criteo"
      end
    end

  end

  describe "#instock" do
    it "returns 1 when product is in stock" do
      subject.stub(:inventory).and_return(1)
      subject.instock.should == "1"
    end

    it "returns 0 when product is not in stock" do
      subject.stub(:inventory).and_return(0)
      subject.instock.should == "0"
    end
  end

  describe "#gift_price" do
    it "calls GiftDiscountService passing the product, the position and returns it" do
      GiftDiscountService.should_receive(:price_for_product).with(subject,1).and_return(69.90)
      subject.gift_price(1).should == 69.90
    end
  end

  describe "#subcategory" do
    it "gets the subcategory from the product details" do
      subject.should_receive(:subcategory_name).and_return("Pulseira")
      subject.subcategory.should == "Pulseira"
    end
  end

  describe "#promotion?" do
    it "return false when price is same of retail price" do
      subject.stub(:price => 123.45)
      subject.stub(:retail_price => 123.45)
      subject.promotion?.should be_false
    end

    it "return true when price has difference of retail price" do
      subject.stub(:price => 123.45)
      subject.stub(:retail_price => 100.45)
      subject.promotion?.should be_true
    end
  end

  describe "#share_by_email" do
    context "when has one email to send" do
      informations = { name_from: "User name", email_from: "user@email.com", emails_to_deliver: "user_friend@email.com" }
       it "receives share mailer deliver" do
         ShareProductMailer.should_receive(:send_share_message_for).with(subject, informations, informations[:emails_to_deliver].split(/,|;|\r|\t/).map(&:strip).first)
         subject.share_by_email(informations)
       end
    end
    context "when has N emails to send" do
      informations = { name_from: "User name", email_from: "user@email.com", emails_to_deliver: "user_friend@email.com, another_friend@email.com, third_fiend@email.com" }
       it "receives share mailer deliver 3 times" do
         ShareProductMailer.should_receive(:send_share_message_for).with(subject, informations, informations[:emails_to_deliver].split(/,|;|\r|\t/).map(&:strip).first)

         ShareProductMailer.should_receive(:send_share_message_for).with(subject, informations, informations[:emails_to_deliver].split(/,|;|\r|\t/).map(&:strip).second)

         ShareProductMailer.should_receive(:send_share_message_for).with(subject, informations, informations[:emails_to_deliver].split(/,|;|\r|\t/).map(&:strip).third)

         subject.share_by_email(informations)
       end
    end
  end

  describe "#shoe_inventory_has_less_than_minimum?" do
    let(:shoe_for_xml) { FactoryGirl.create :blue_sliper_with_variants }

    context "shoe with less than 3 variants" do
      it "returns true" do
        # leave only 2 variants on factory
        shoe_for_xml.variants.first(2).each {|v| v.destroy}
        shoe_for_xml.shoe_inventory_has_less_than_minimum?.should be_true
      end
    end

    context "shoe with 3 or more  variants" do

      context "but with less than 3 inventory in any of them" do
        it "returns true" do
          # set inventory to less than 3 on each variant
          shoe_for_xml.variants.each {|v| v.update_attribute(:inventory, 2)}
          shoe_for_xml.shoe_inventory_has_less_than_minimum?.should be_true
        end
      end

      context "with 3 or more inventory each" do
        it "returns false" do
          shoe_for_xml.shoe_inventory_has_less_than_minimum?.should be_false
        end
      end
    end

    context "products that aren't shoes" do
      let(:basic_bag_for_xml) { FactoryGirl.create(:basic_bag) }

      it "returns false" do
        basic_bag_for_xml.shoe_inventory_has_less_than_minimum?.should be_false
      end
    end

  end

  describe 'find_suggested_products' do
    context "when product has suggested products" do
      let!(:first_shoe) { FactoryGirl.create(:shoe) }
      let!(:second_shoe) { FactoryGirl.create(:red_slipper, collection_id: 1) }
      let!(:third_shoe) { FactoryGirl.create(:silver_slipper, collection_id: 1) }
      let!(:subcategory) { FactoryGirl.create(:shoe_subcategory_name, product: second_shoe) }
      let!(:another_subcategory) { FactoryGirl.create(:shoe_subcategory_name, product: third_shoe) }

      before do
        first_shoe.stub(:subcategory).and_return("Scarpin")
        second_shoe.stub(:subcategory).and_return("Sandalia")
        third_shoe.stub(:subcategory).and_return("Sandalia")
        subject.stub(:subcategory).and_return("Sandalia")
        subject.stub(:collection_id).and_return(1)
      end

      it "returns suggested products" do
        subject.find_suggested_products.should_not include (first_shoe)
        subject.find_suggested_products.should include (second_shoe)
        subject.find_suggested_products.should include (third_shoe)
      end

    end
  end

  describe "#item_view_cache_key_for" do
    context "when product is shoe" do
      subject { FactoryGirl.build(:shoe, id: 10) }
      context "and has shoe_size 37" do
        it { expect(subject.item_view_cache_key_for("37")).to eq(CACHE_KEYS[:product_item_partial_shoe][:key] % [subject.id, 37]) }
      end

      context "and has no shoe_size" do
        it { expect(subject.item_view_cache_key_for).to eq(CACHE_KEYS[:product_item_partial_shoe][:key] % [subject.id, nil]) }
      end
    end

    context "when product is not a shoe" do
      subject { FactoryGirl.build(:bag, id: 10) }
      it { expect(subject.item_view_cache_key_for).to eq(CACHE_KEYS[:product_item_partial][:key] % subject.id) }
    end
  end

  describe "#delete_cache" do
    context "when product is a shoe" do
      subject { FactoryGirl.create(:shoe, :in_stock) }
      it "deletes all product keys cache" do
        subject.variants.collect(&:description).each do |shoe_size|
          Rails.cache.should_receive(:delete).with("views/#{subject.item_view_cache_key_for(shoe_size)}")
        end
        Rails.cache.should_receive(:delete).with("views/#{subject.item_view_cache_key_for}")
        subject.delete_cache
      end
    end

    context "when product is not a shoe" do
      subject { FactoryGirl.create(:bag) }
      it "deletes all product keys cache" do
        Rails.cache.should_receive(:delete).with("views/#{subject.item_view_cache_key_for}")
        subject.delete_cache
      end
    end
  end

end
