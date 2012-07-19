# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :clean_order, :class => Order do
    association :payment, :factory => :billet
    association :freight, :factory => :freight

    after_build do |order|
      Resque.stub(:enqueue)
    end
  end

  factory :restricted_order, :class => Order do
    association :payment, :factory => :billet
    association :freight, :factory => :freight
    restricted true

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
      Resque.stub(:enqueue_in)
    end

    after_create do |order|
      order.stub(:total).and_return(BigDecimal.new("100"))
      order.stub(:reload)
    end
  end

  factory :authorized_order, :class => Order do
    association :payment, :factory => :credit_card_with_response
    association :freight, :factory => :freight
    state "authorized"
    after_build do |order|
      Resque.stub(:enqueue)
      Resque.stub(:enqueue_in)
    end

    after_create do |order|
      order.stub(:total).and_return(BigDecimal.new("100"))
      order.stub(:reload)
    end
  end

  factory :delivered_order, :class => Order do
    association :payment, :factory => :billet
    association :freight, :factory => :freight
    association :user
    state "delivered"

    after_create do |order|
      order.stub(:line_items_total).and_return(BigDecimal.new("99.90"))
      order.stub(:reload)
    end
  end
end
