require 'rspec/expectations/extensions'
require 'rspec/matchers'
require 'rspec/expectations/fail_with'
require 'rspec/expectations/errors'
require 'rspec/expectations/deprecation'
require 'rspec/expectations/handler'
require 'rspec/expectations/version'
require 'rspec/expectations/differ'

module RSpec
  # RSpec::Expectations adds two instance methods to every object:
  #
  #     should(matcher=nil)
  #     should_not(matcher=nil)
  #
  # Both methods take an optional matcher object (See
  # [RSpec::Matchers](../RSpec/Matchers)).  When `should` is invoked with a
  # matcher, it turns around and calls `matcher.matches?(self)`.  For example,
  # in the expression:
  #
  #     order.total.should eq(Money.new(5.55, :USD))
  #
  # the `should` method invokes the equivalent of `eq.matches?(order.total)`. If
  # `matches?` returns true, the expectation is met and execution continues. If
  # `false`, then the spec fails with the message returned by
  # `eq.failure_message_for_should`.
  #
  # Given the expression:
  #
  #     order.entries.should_not include(entry)
  #
  # the `should_not` method invokes the equivalent of
  # `include.matches?(order.entries)`, but it interprets `false` as success, and
  # `true` as a failure, using the message generated by
  # `eq.failure_message_for_should_not`.
  #
  # rspec-expectations ships with a standard set of useful matchers, and writing
  # your own matchers is quite simple. 
  #
  # See [RSpec::Matchers](../RSpec/Matchers) for more information about the
  # built-in matchers that ship with rspec-expectations, and how to write your
  # own custom matchers.
  module Expectations
  end
end
