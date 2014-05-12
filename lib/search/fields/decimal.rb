module Search
  module Fields
    class Decimal < Search::Field
      def value
        normalize_decimal_numbers(@value, @options[:scale])
      end

      def normalize_decimal_numbers(val, scale)
        BigDecimal.new(val.to_d/(10**scale.to_d))
      end
    end
  end
end

