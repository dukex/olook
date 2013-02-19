# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :lookbook do

    factory :basic_lookbook do
      name "Basic_Lookbook"
      slug "Basic_Lookbook"
    end

    factory :complex_lookbook do
      name "Complex_Lookbook"
      slug "Complex_Lookbook"
      after_create do |lookbook|
        lookbook.products << FactoryGirl.create(:shoe, :casual)
      end
    end

  end
end
