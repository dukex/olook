require 'spec_helper'

share_examples_for "finds definitions" do
  before do
    FactoryGirl.stubs(:load)
    FactoryGirl.find_definitions
  end

  subject { FactoryGirl }
end

RSpec::Matchers.define :load_definitions_from do |file|
  match do |given|
    @has_received = have_received(:load).with(File.expand_path(file))
    @has_received.matches?(given)
  end

  description do
    "load definitions from #{file}"
  end

  failure_message_for_should do
    @has_received.failure_message
  end
end

describe "definition loading" do
  def self.in_directory_with_files(*files)
    before do
      @pwd = Dir.pwd
      @tmp_dir = File.join(File.dirname(__FILE__), 'tmp')
      FileUtils.mkdir_p @tmp_dir
      Dir.chdir(@tmp_dir)

      files.each do |file|
        FileUtils.mkdir_p File.dirname(file)
        FileUtils.touch file
      end
    end

    after do
      Dir.chdir(@pwd)
      FileUtils.rm_rf(@tmp_dir)
    end
  end

  describe "with factories.rb" do
    in_directory_with_files 'factories.rb'
    it_should_behave_like "finds definitions" do
      it { should load_definitions_from('factories.rb') }
    end
  end

  %w(spec test).each do |dir|
    describe "with a factories file under #{dir}" do
      in_directory_with_files File.join(dir, 'factories.rb')
      it_should_behave_like "finds definitions" do
        it { should load_definitions_from("#{dir}/factories.rb") }
      end
    end

    describe "with a factories file under #{dir}/factories" do
      in_directory_with_files File.join(dir, 'factories', 'post_factory.rb')
      it_should_behave_like "finds definitions" do
        it { should load_definitions_from("#{dir}/factories/post_factory.rb") }
      end
    end

    describe "with several factories files under #{dir}/factories" do
      in_directory_with_files File.join(dir, 'factories', 'post_factory.rb'),
                              File.join(dir, 'factories', 'person_factory.rb')
      it_should_behave_like "finds definitions" do
        it { should load_definitions_from("#{dir}/factories/post_factory.rb") }
        it { should load_definitions_from("#{dir}/factories/person_factory.rb") }
      end
    end

    describe "with several factories files under #{dir}/factories in non-alphabetical order" do
      in_directory_with_files File.join(dir, 'factories', 'b.rb'),
                              File.join(dir, 'factories', 'a.rb')
      it "loads the files in the right order" do
        FactoryGirl.stubs(:load)
        sorted_load_order = sequence("load order")
        FactoryGirl.expects(:load).with(includes("a.rb")).in_sequence(sorted_load_order)
        FactoryGirl.expects(:load).with(includes("b.rb")).in_sequence(sorted_load_order)
        FactoryGirl.find_definitions
      end
    end

    describe "with nested and unnested factories files under #{dir}" do
      in_directory_with_files File.join(dir, 'factories.rb'),
                              File.join(dir, 'factories', 'post_factory.rb'),
                              File.join(dir, 'factories', 'person_factory.rb')
      it_should_behave_like "finds definitions" do
        it { should load_definitions_from("#{dir}/factories.rb") }
        it { should load_definitions_from("#{dir}/factories/post_factory.rb") }
        it { should load_definitions_from("#{dir}/factories/person_factory.rb") }
      end
    end

    describe "with deeply nested factory files under #{dir}" do
      in_directory_with_files File.join(dir, 'factories', 'subdirectory', 'post_factory.rb'),
                              File.join(dir, 'factories', 'subdirectory', 'person_factory.rb')
      it_should_behave_like "finds definitions" do
        it { should load_definitions_from("#{dir}/factories/subdirectory/post_factory.rb") }
        it { should load_definitions_from("#{dir}/factories/subdirectory/person_factory.rb") }
      end
    end
  end
end
