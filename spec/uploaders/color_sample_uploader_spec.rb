# # -*- encoding : utf-8 -*-
# require "spec_helper"

# describe ColorSampleUploader do
#   include CarrierWave::Test::Matchers

#   let(:valid_image)   { File.join fixture_path, 'valid_image.jpg' }
#   let(:invalid_image) { File.join fixture_path, 'invalid_image.txt' }
#   let(:product)       { FactoryGirl.create :basic_shoe }

#   subject { described_class.new(product, :color_sample) }

#   describe "an uploaded image" do
#     before :all do
#       subject.store!(File.open(valid_image))
#     end

#     it "should exist" do
#      subject.path.should be_true
#     end
#   end

#   it "should only allow the uploading of image files" do
#     expect {
#       subject.store!(File.open(invalid_image))
#     }.to raise_error(CarrierWave::IntegrityError)
#   end

#   it 'should store images on directories with the product model name' do
#     subject.stub_chain(:model, :class, :name, :underscore, :pluralize).and_return('dir')
#     subject.stub_chain(:model, :model_number).and_return('product')
#     subject.store_dir.should == "dir/product"
#   end
# end
