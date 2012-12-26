Feature: pattern option

  By default, RSpec loads files matching the pattern:

      "spec/**/*_spec.rb"

  Use the `--pattern` option to declare a different pattern.

  Scenario: default pattern
    Given a file named "spec/example_spec.rb" with:
      """
      describe "addition" do
        it "adds things" do
          (1 + 2).should eq(3)
        end
      end
      """
    When I run `rspec`
    Then the output should contain "1 example, 0 failures"

  Scenario: override the default pattern on the command line
    Given a file named "spec/example.spec" with:
      """
      describe "addition" do
        it "adds things" do
          (1 + 2).should eq(3)
        end
      end
      """
    When I run `rspec --pattern "spec/**/*.spec"`
    Then the output should contain "1 example, 0 failures"
