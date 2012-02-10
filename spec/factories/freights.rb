# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :freight do
    delivery_time 4
    price 10.23
    cost 5.67
    association :address, :factory => :address
  end
end
