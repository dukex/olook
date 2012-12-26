require 'spec_helper'

# Generators are not automatically loaded by Rails
require 'generators/rspec/helper/helper_generator'

describe Rspec::Generators::HelperGenerator do
  # Tell the generator where to put its output (what it thinks of as Rails.root)
  destination File.expand_path("../../../../../tmp", __FILE__)

  before { prepare_destination }

  subject { file('spec/helpers/posts_helper_spec.rb') }
  describe 'generated by default' do
    before do
      run_generator %w(posts)
    end

    describe 'the spec' do
      it { should exist }
      it { should contain(/require 'spec_helper'/) }
      it { should contain(/describe PostsHelper/) }
    end
  end
  describe 'skipped with a flag' do
    before do
      run_generator %w(posts --no-helper_specs)
    end
    it { should_not exist }
  end
end
