Feature: inclusion filters

  You can constrain which examples are run by declaring an inclusion filter. The
  most common use case is to focus on a subset of examples as you're focused on
  a particular problem.

  You can specify metadata using only symbols if you set the
  `treat_symbols_as_metadata_keys_with_true_values` config option to `true`.

  Background:
    Given a file named "spec/spec_helper.rb" with:
      """
      RSpec.configure do |c|
        c.filter_run_including :focus => true
      end
      """

  Scenario: focus on an example
    Given a file named "spec/sample_spec.rb" with:
      """
      require "spec_helper"

      describe "something" do
        it "does one thing" do
        end

        it "does another thing", :focus => true do
        end
      end
      """
    When I run `rspec spec/sample_spec.rb --format doc`
    Then the output should contain "does another thing"
    And the output should not contain "does one thing"

  Scenario: focus on a group
    Given a file named "spec/sample_spec.rb" with:
      """
      require "spec_helper"

      describe "group 1", :focus => true do
        it "group 1 example 1" do
        end

        it "group 1 example 2" do
        end
      end

      describe "group 2" do
        it "group 2 example 1" do
        end
      end
      """
    When I run `rspec spec/sample_spec.rb --format doc`
    Then the output should contain "group 1 example 1"
    And  the output should contain "group 1 example 2"
    And  the output should not contain "group 2 example 1"

  Scenario: before/after(:all) hooks in unmatched example group are not run
    Given a file named "spec/before_after_all_inclusion_filter_spec.rb" with:
      """
      require "spec_helper"

      describe "group 1", :focus => true do
        before(:all) { puts "before all in focused group" }
        after(:all)  { puts "after all in focused group"  }

        it "group 1 example" do
        end
      end

      describe "group 2" do
        before(:all) { puts "before all in unfocused group" }
        after(:all)  { puts "after all in unfocused group"  }

        context "context 1" do
          it "group 2 context 1 example 1" do
          end
        end
      end
      """
    When I run `rspec ./spec/before_after_all_inclusion_filter_spec.rb`
    Then the output should contain "before all in focused group"
     And the output should contain "after all in focused group"
     And the output should not contain "before all in unfocused group"
     And the output should not contain "after all in unfocused group"

  Scenario: Use symbols as metadata
    Given a file named "symbols_as_metadata_spec.rb" with:
      """
      RSpec.configure do |c|
        c.treat_symbols_as_metadata_keys_with_true_values = true
        c.filter_run :current_example
      end

      describe "something" do
        it "does one thing" do
        end

        it "does another thing", :current_example do
        end
      end
      """
    When I run `rspec symbols_as_metadata_spec.rb --format doc`
    Then the output should contain "does another thing"
    And the output should not contain "does one thing"
