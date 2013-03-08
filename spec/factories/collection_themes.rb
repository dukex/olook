# -*- encoding : utf-8 -*-
include ActionDispatch::TestProcess
FactoryGirl.define do
  factory :collection_theme do
    name "dia-a-dia"
    slug "dia-a-dia"
    article "Para a"
    header_image { fixture_file_upload("#{Rails.root}/spec/fixtures/files/shoe02.jpg", "image/jpeg") }
    position 1
    active true
  end

  factory :collection_themes, :class => CollectionTheme do
    sequence :name do |n|
      "moment#{n}"
    end
    sequence :slug do |n|
      "moment#{n}"
    end
    active true
    header_image { fixture_file_upload("#{Rails.root}/spec/fixtures/files/shoe02.jpg", "image/jpeg") }
    article "Para a"
    position 2
  end
end
