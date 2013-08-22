# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Abacos::IntegrateProductsObserver do
  describe '.products_to_be_integrated' do
    it "sets how many products will be integrated" do
      REDIS.should_receive(:set).with("products_to_integrate",10)
      described_class.products_to_be_integrated(10)
    end
  end

  describe '.mark_product_integrated_as_success!' do
    it "decrements one product that had the integration product done" do
      REDIS.should_receive(:decrby).with("products_to_integrate", 1)
      described_class.mark_product_integrated_as_success!
    end
  end

  describe '.mark_product_integrated_as_failure!' do
    it "decrements one product that had the integration product done" do
      REDIS.should_receive(:decrby).with("products_to_integrate", 1)
      described_class.mark_product_integrated_as_failure!("product_number", "error_message")
    end

    it "creates on redis a error message with id" do
      REDIS.should_receive(:mapped_hmset).with("integration_errors", { "1" => "error message" })
      described_class.mark_product_integrated_as_failure!(1, "error message")
    end
  end

  describe '.perform' do
    let(:opts) { {
        user: 'bob@dylan.com',
        products_amount: 10
    } }

    context "when integration is finished" do
      before do
        REDIS.stub(:get).and_return("0")
      end
      it "sends alert notification" do
        IntegrationProductsAlert.should_receive(:notify).with(opts)
        described_class.perform(opts)
      end
    end

    context "when integration is not finished" do
      before do
        REDIS.stub(:get).and_return("1")
      end

      it "enqueues verification from now to 5 minutes" do
        Resque.should_receive(:enqueue_in).with(5.minutes, described_class, opts)
        described_class.perform(opts)
      end
    end
  end
end
