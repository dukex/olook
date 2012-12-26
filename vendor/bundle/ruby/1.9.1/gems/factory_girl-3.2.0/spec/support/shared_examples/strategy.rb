shared_examples_for "strategy without association support" do
  let(:factory)   { stub("associate_factory") }
  let(:attribute) { FactoryGirl::Attribute::Association.new(:user, :user, {}) }

  def association_named(name, overrides)
    runner = FactoryGirl::FactoryRunner.new(name, FactoryGirl::Strategy::Build, [overrides])
    subject.association(runner)
  end

  before do
    FactoryGirl.stubs(factory_by_name: factory)
    factory.stubs(:compile)
    factory.stubs(:run)
  end

  it "returns nil when accessing an association" do
    association_named(:user, {}).should be_nil
  end
end

shared_examples_for "strategy with association support" do |factory_girl_strategy_class|
  let(:factory) { stub("associate_factory") }

  def association_named(name, strategy, overrides)
    runner = FactoryGirl::FactoryRunner.new(name, strategy, [overrides])
    subject.association(runner)
  end

  before do
    FactoryGirl.stubs(factory_by_name: factory)
    factory.stubs(:compile)
    factory.stubs(:run)
  end

  it "runs the factory with the correct overrides" do
    association_named(:author, factory_girl_strategy_class, great: "value")
    factory.should have_received(:run).with(factory_girl_strategy_class, great: "value")
  end

  it "finds the factory with the correct factory name" do
    association_named(:author, factory_girl_strategy_class, great: "value")
    FactoryGirl.should have_received(:factory_by_name).with(:author)
  end
end

shared_examples_for "strategy with strategy: :build" do |factory_girl_strategy_class|
  let(:factory) { stub("associate_factory") }

  def association_named(name, overrides)
    strategy = FactoryGirl::StrategyCalculator.new(overrides[:strategy]).strategy
    runner = FactoryGirl::FactoryRunner.new(name, strategy, [overrides.except(:strategy)])
    subject.association(runner)
  end

  before do
    FactoryGirl.stubs(factory_by_name: factory)
    factory.stubs(:compile)
    factory.stubs(:run)
  end

  it "runs the factory with the correct overrides" do
    association_named(:author, strategy: :build, great: "value")
    factory.should have_received(:run).with(factory_girl_strategy_class, { great: "value" })
  end

  it "finds the factory with the correct factory name" do
    association_named(:author, strategy: :build, great: "value")
    FactoryGirl.should have_received(:factory_by_name).with(:author)
  end
end

shared_examples_for "strategy with callbacks" do |*callback_names|
  let(:result_instance) do
    define_class("ResultInstance") do
      attr_accessor :id
    end.new
  end

  let(:evaluation) { stub("evaluation", object: result_instance, notify: true, create: nil) }

  it "runs the callbacks #{callback_names} with the evaluation's object" do
    subject.result(evaluation)
    callback_names.each do |name|
      evaluation.should have_received(:notify).with(name, evaluation.object)
    end
  end

  it "returns the object from the evaluation" do
    subject.result(evaluation).should == evaluation.object
  end
end
