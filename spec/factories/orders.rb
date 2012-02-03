# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :order_without_payment, :class => Order do
    association :freight, :factory => :freight

    after_build do |order|
      Resque.stub(:enqueue)
    end
  end

  factory :clean_order, :class => Order do
    association :payment, :factory => :billet
    association :freight, :factory => :freight

    after_build do |order|
      Resque.stub(:enqueue)
    end
  end

  factory :clean_order_credit_card, :class => Order do
    association :payment, :factory => :credit_card
    association :freight, :factory => :freight

    after_build do |order|
      Resque.stub(:enqueue)
    end
  end

  factory :order do
    association :payment, :factory => :billet
    association :freight, :factory => :freight

    after_build do |order|
      Resque.stub(:enqueue)
    end

    after_create do |order|
      order.stub(:total).and_return(100)
      order.stub(:reload)
    end
  end

  factory :delivered_order, :class => Order do
    association :payment, :factory => :billet
    association :freight, :factory => :freight
    association :user
    state "delivered"
  end
end
