module Search
  module Fields
    module V20130101
      class Boolean < Search::V20110201::Field
        def value
          @value == '1'
        end
      end
    end
  end
end

