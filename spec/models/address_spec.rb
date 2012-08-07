require "spec_helper"

describe Address do
  subject { FactoryGirl.build(:address) }

  context "attributes validation" do
    it { should be_valid }

    it { should validate_presence_of(:number) }
    it { should validate_numericality_of(:number) }
    it { should validate_presence_of(:country) }
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:street) }
    it { should validate_presence_of(:city) }
    it { should validate_presence_of(:zip_code) }
    it { should validate_presence_of(:neighborhood) }
    it { should validate_presence_of(:telephone) }

    it "should validate the Zip Format" do
      subject.zip_code = "12345-09"
      subject.should_not be_valid
    end

    it "the telephone format should be valid" do
      subject.telephone = "(34)8978-9236"
      subject.should be_valid
    end

    it "the telephone format should not be valid" do
      subject.telephone = "(34)89789236"
      subject.should_not be_valid
    end

    it "the telephone format for DDD 11 should be valid" do
      subject.telephone = "(11)98978-9236"
      subject.should be_valid
    end

    it "the telephone format for DDD 11 should not be valid" do
      subject.telephone = "(11)989789236"
      subject.should_not be_valid
    end

    it "should validate the state format" do
      subject.state = "mg"
      subject.should be_valid
    end
  end

  describe "#identification" do
    it "should return the first name + the last name" do
      FactoryGirl.build(:address, :first_name => "My", :last_name => "Home").identification.should eql("My Home")
    end
  end
end
