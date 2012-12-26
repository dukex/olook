module Shoulda
  module Matchers
    module ActiveRecord
      # Ensures that the model can accept nested attributes for the specified
      # association.
      #
      # Options:
      # * <tt>allow_destroy</tt> - Whether or not to allow destroy
      # * <tt>limit</tt> - Max number of nested attributes
      # * <tt>update_only</tt> - Only allow updates
      #
      # Example:
      #   it { should accept_nested_attributes_for(:friends) }
      #   it { should accept_nested_attributes_for(:friends).
      #                 allow_destroy(true).
      #                 limit(4) }
      #   it { should accept_nested_attributes_for(:friends).
      #                 update_only(true) }
      #
      def accept_nested_attributes_for(name)
        AcceptNestedAttributesForMatcher.new(name)
      end

      class AcceptNestedAttributesForMatcher
        def initialize(name)
          @name = name
          self
        end

        def allow_destroy(allow_destroy)
          @allow_destroy = allow_destroy
          self
        end

        def limit(limit)
          @limit = limit
          self
        end

        def update_only(update_only)
          @update_only = update_only
          self
        end

        def matches?(subject)
          @subject = subject
          exists? &&
            allow_destroy_correct? &&
            limit_correct? &&
            update_only_correct?
        end

        def failure_message
          "Expected #{expectation} (#{@problem})"
        end

        def negative_failure_message
          "Did not expect #{expectation}"
        end

        def description
          description = "accepts_nested_attributes_for :#{@name}"
          description += " allow_destroy => #{@allow_destroy}" if @allow_destroy
          description += " limit => #{@limit}" if @limit
          description += " update_only => #{@update_only}" if @update_only
          description
        end

        protected

        def exists?
          if config
            true
          else
            @problem = "is not declared"
            false
          end
        end

        def allow_destroy_correct?
          if @allow_destroy.nil? || @allow_destroy == config[:allow_destroy]
            true
          else
            @problem = (@allow_destroy ? "should" : "should not") +
              " allow destroy"
            false
          end
        end

        def limit_correct?
          if @limit.nil? || @limit == config[:limit]
            true
          else
            @problem = "limit should be #@limit, got #{config[:limit]}"
            false
          end
        end

        def update_only_correct?
          if @update_only.nil? || @update_only == config[:update_only]
            true
          else
            @problem = (@update_only ? "should" : "should not") +
              " be update only"
            false
          end
        end

        def config
          model_config[@name]
        end

        def model_config
          model_class.nested_attributes_options
        end

        def model_class
          @subject.class
        end

        def expectation
          "#{model_class.name} to accept nested attributes for #{@name}"
        end
      end
    end
  end
end
