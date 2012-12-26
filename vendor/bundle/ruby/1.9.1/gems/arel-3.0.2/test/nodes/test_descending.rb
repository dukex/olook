require 'helper'

module Arel
  module Nodes
    class TestDescending < MiniTest::Unit::TestCase
      def test_construct
        descending = Descending.new 'zomg'
        assert_equal 'zomg', descending.expr
      end

      def test_reverse
        descending = Descending.new 'zomg'
        ascending = descending.reverse
        assert_kind_of Ascending, ascending
        assert_equal descending.expr, ascending.expr
      end

      def test_direction
        descending = Descending.new 'zomg'
        assert_equal :desc, descending.direction
      end

      def test_ascending?
        descending = Descending.new 'zomg'
        assert !descending.ascending?
      end

      def test_descending?
        descending = Descending.new 'zomg'
        assert descending.descending?
      end
    end
  end
end
