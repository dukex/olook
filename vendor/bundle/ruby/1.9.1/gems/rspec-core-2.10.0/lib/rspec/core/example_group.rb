module RSpec
  module Core
    # ExampleGroup and Example are the main structural elements of rspec-core.
    # Consider this example:
    #
    #     describe Thing do
    #       it "does something" do
    #       end
    #     end
    #
    # The object returned by `describe Thing` is a subclass of ExampleGroup.
    # The object returned by `it "does something"` is an instance of Example,
    # which serves as a wrapper for an instance of the ExampleGroup in which it
    # is declared.
    class ExampleGroup
      extend  MetadataHashBuilder::WithDeprecationWarning
      extend  Extensions::ModuleEvalWithArgs
      extend  Subject::ExampleGroupMethods
      extend  Hooks

      include Extensions::InstanceEvalWithArgs
      include Subject::ExampleMethods
      include Pending
      include Let

      # @private
      def self.world
        RSpec.world
      end

      # @private
      def self.register
        world.register(self)
      end

      class << self
        # @private
        def self.delegate_to_metadata(*names)
          names.each do |name|
            define_method name do
              metadata[:example_group][name]
            end
          end
        end

        delegate_to_metadata :description, :described_class, :file_path
        alias_method :display_name, :description
        # @private
        alias_method :describes, :described_class
      end

      # @private
      def self.define_example_method(name, extra_options={})
        module_eval(<<-END_RUBY, __FILE__, __LINE__)
          def self.#{name}(desc=nil, *args, &block)
            options = build_metadata_hash_from(args)
            options.update(:pending => RSpec::Core::Pending::NOT_YET_IMPLEMENTED) unless block
            options.update(#{extra_options.inspect})
            examples << RSpec::Core::Example.new(self, desc, options, block)
            examples.last
          end
        END_RUBY
      end

      define_example_method :example
      define_example_method :it
      define_example_method :specify

      define_example_method :focused,  :focused => true, :focus => true
      define_example_method :focus,    :focused => true, :focus => true

      define_example_method :pending,  :pending => true
      define_example_method :xexample, :pending => 'Temporarily disabled with xexample'
      define_example_method :xit,      :pending => 'Temporarily disabled with xit'
      define_example_method :xspecify, :pending => 'Temporarily disabled with xspecify'

      class << self
        alias_method :alias_example_to, :define_example_method
      end

      # @private
      def self.define_nested_shared_group_method(new_name, report_label=nil)
        module_eval(<<-END_RUBY, __FILE__, __LINE__)
          def self.#{new_name}(name, *args, &customization_block)
            group = describe("#{report_label || "it should behave like"} \#{name}") do
              find_and_eval_shared("examples", name, *args, &customization_block)
            end
            group.metadata[:shared_group_name] = name
            group
          end
        END_RUBY
      end

      define_nested_shared_group_method :it_should_behave_like

      class << self
        alias_method :alias_it_should_behave_like_to, :define_nested_shared_group_method
      end

      alias_it_should_behave_like_to :it_behaves_like, "behaves like"

      # Includes shared content declared with `name`.
      #
      # @see SharedExampleGroup
      def self.include_context(name, *args)
        block_given? ? block_not_supported("context") : find_and_eval_shared("context", name, *args)
      end

      # Includes shared content declared with `name`.
      #
      # @see SharedExampleGroup
      def self.include_examples(name, *args)
        block_given? ? block_not_supported("examples") : find_and_eval_shared("examples", name, *args)
      end

      # @private
      def self.block_not_supported(label)
        warn("Customization blocks not supported for include_#{label}.  Use it_behaves_like instead.")
      end

      # @private
      def self.find_and_eval_shared(label, name, *args, &customization_block)
        raise ArgumentError, "Could not find shared #{label} #{name.inspect}" unless
          shared_block = world.shared_example_groups[name]

        module_eval_with_args(*args, &shared_block)
        module_eval(&customization_block) if customization_block
      end

      # @private
      def self.examples
        @examples ||= []
      end

      # @private
      def self.filtered_examples
        world.filtered_examples[self]
      end

      # @private
      def self.descendant_filtered_examples
        @descendant_filtered_examples ||= filtered_examples + children.inject([]){|l,c| l + c.descendant_filtered_examples}
      end

      # The [Metadata](Metadata) object associated with this group.
      # @see Metadata
      def self.metadata
        @metadata if defined?(@metadata)
      end

      # @private
      # @return [Metadata] belonging to the parent of a nested [ExampleGroup](ExampleGroup)
      def self.superclass_metadata
        @superclass_metadata ||= self.superclass.respond_to?(:metadata) ? self.superclass.metadata : nil
      end

      # Generates a subclass of this example group which inherits
      # everything except the examples themselves.
      #
      # ## Examples
      #
      #     describe "something" do # << This describe method is defined in
      #                             # << RSpec::Core::DSL, included in the
      #                             # << global namespace
      #       before do
      #         do_something_before
      #       end
      #
      #       let(:thing) { Thing.new }
      #
      #       describe "attribute (of something)" do
      #         # examples in the group get the before hook
      #         # declared above, and can access `thing`
      #       end
      #     end
      #
      # @see DSL#describe
      def self.describe(*args, &example_group_block)
        @_subclass_count ||= 0
        @_subclass_count += 1
        args << {} unless args.last.is_a?(Hash)
        args.last.update(:example_group_block => example_group_block)

        # TODO 2010-05-05: Because we don't know if const_set is thread-safe
        child = const_set(
          "Nested_#{@_subclass_count}",
          subclass(self, args, &example_group_block)
        )
        children << child
        child
      end

      class << self
        alias_method :context, :describe
      end

      # @private
      def self.subclass(parent, args, &example_group_block)
        subclass = Class.new(parent)
        subclass.set_it_up(*args)
        subclass.module_eval(&example_group_block) if example_group_block
        subclass
      end

      # @private
      def self.children
        @children ||= [].extend(Extensions::Ordered)
      end

      # @private
      def self.descendants
        @_descendants ||= [self] + children.inject([]) {|list, c| list + c.descendants}
      end

      # @private
      def self.ancestors
        @_ancestors ||= super().select {|a| a < RSpec::Core::ExampleGroup}
      end

      # @private
      def self.top_level?
        @top_level ||= superclass == ExampleGroup
      end

      # @private
      def self.ensure_example_groups_are_configured
        unless defined?(@@example_groups_configured)
          RSpec.configuration.configure_mock_framework
          RSpec.configuration.configure_expectation_framework
          @@example_groups_configured = true
        end
      end

      # @private
      def self.set_it_up(*args)
        # Ruby 1.9 has a bug that can lead to infinite recursion and a
        # SystemStackError if you include a module in a superclass after
        # including it in a subclass: https://gist.github.com/845896
        # To prevent this, we must include any modules in RSpec::Core::ExampleGroup
        # before users create example groups and have a chance to include
        # the same module in a subclass of RSpec::Core::ExampleGroup.
        # So we need to configure example groups here.
        ensure_example_groups_are_configured

        symbol_description = args.shift if args.first.is_a?(Symbol)
        args << build_metadata_hash_from(args)
        args.unshift(symbol_description) if symbol_description
        @metadata = RSpec::Core::Metadata.new(superclass_metadata).process(*args)
        world.configure_group(self)
        [:before, :after, :around].each do |_when|
          RSpec.configuration.hooks[_when][:each].each do |hook|
            unless ancestors.any? {|a| a.hooks[_when][:each].include? hook }
              hooks[_when][:each] << hook # each's get filtered later per example
            end
          end
          next if _when == :around # no around(:all) hooks
          RSpec.configuration.hooks[_when][:all].each do |hook|
            unless ancestors.any? {|a| a.hooks[_when][:all].include? hook }
              hooks[_when][:all] << hook if hook.options_apply?(self)
            end
          end
        end
      end

      # @private
      def self.before_all_ivars
        @before_all_ivars ||= {}
      end

      # @private
      def self.store_before_all_ivars(example_group_instance)
        return if example_group_instance.instance_variables.empty?
        example_group_instance.instance_variables.each { |ivar|
          before_all_ivars[ivar] = example_group_instance.instance_variable_get(ivar)
        }
      end

      # @private
      def self.assign_before_all_ivars(ivars, example_group_instance)
        ivars.each { |ivar, val| example_group_instance.instance_variable_set(ivar, val) }
      end

      # @private
      def self.run_before_all_hooks(example_group_instance)
        return if descendant_filtered_examples.empty?
        assign_before_all_ivars(superclass.before_all_ivars, example_group_instance)
        run_hook(:before, :all, example_group_instance)
        store_before_all_ivars(example_group_instance)
      end

      # @private
      def self.run_around_each_hooks(example, initial_procsy)
        run_hook(:around, :each, example, initial_procsy)
      end

      # @private
      def self.run_before_each_hooks(example)
        run_hook(:before, :each, example)
      end

      # @private
      def self.run_after_each_hooks(example)
        run_hook(:after, :each, example)
      end

      # @private
      def self.run_after_all_hooks(example_group_instance)
        return if descendant_filtered_examples.empty?
        assign_before_all_ivars(before_all_ivars, example_group_instance)

        begin
          run_hook(:after, :all, example_group_instance)
        rescue => e
          # TODO: come up with a better solution for this.
          RSpec.configuration.reporter.message <<-EOS

An error occurred in an after(:all) hook.
  #{e.class}: #{e.message}
  occurred at #{e.backtrace.first}

        EOS
        end
      end

      # Runs all the examples in this group
      def self.run(reporter)
        if RSpec.wants_to_quit
          RSpec.clear_remaining_example_groups if top_level?
          return
        end
        reporter.example_group_started(self)

        begin
          run_before_all_hooks(new)
          result_for_this_group = run_examples(reporter)
          results_for_descendants = children.ordered.map {|child| child.run(reporter)}.all?
          result_for_this_group && results_for_descendants
        rescue Exception => ex
          fail_filtered_examples(ex, reporter)
        ensure
          run_after_all_hooks(new)
          before_all_ivars.clear
          reporter.example_group_finished(self)
        end
      end

      # @private
      def self.run_examples(reporter)
        filtered_examples.ordered.map do |example|
          next if RSpec.wants_to_quit
          instance = new
          set_ivars(instance, before_all_ivars)
          succeeded = example.run(instance, reporter)
          RSpec.wants_to_quit = true if fail_fast? && !succeeded
          succeeded
        end.all?
      end

      # @private
      def self.fail_filtered_examples(exception, reporter)
        filtered_examples.each { |example| example.fail_with_exception(reporter, exception) }

        children.each do |child|
          reporter.example_group_started(child)
          child.fail_filtered_examples(exception, reporter)
          reporter.example_group_finished(child)
        end
        false
      end

      # @private
      def self.fail_fast?
        RSpec.configuration.fail_fast?
      end

      # @private
      def self.any_apply?(filters)
        metadata.any_apply?(filters)
      end

      # @private
      def self.all_apply?(filters)
        metadata.all_apply?(filters)
      end

      # @private
      def self.declaration_line_numbers
        @declaration_line_numbers ||= [metadata[:example_group][:line_number]] +
          examples.collect {|e| e.metadata[:line_number]} +
          children.inject([]) {|l,c| l + c.declaration_line_numbers}
      end

      # @private
      def self.top_level_description
        ancestors.last.description
      end

      # @private
      def self.set_ivars(instance, ivars)
        ivars.each {|name, value| instance.instance_variable_set(name, value)}
      end

      # @attr_reader
      # Returns the [Example](Example) object that wraps this instance of
      # `ExampleGroup`
      attr_accessor :example

      # @deprecated use [example](ExampleGroup#example-instance_method)
      def running_example
        RSpec.deprecate("running_example", "example")
        example
      end

      # Returns the class or module passed to the `describe` method (or alias).
      # Returns nil if the subject is not a class or module.
      # @example
      #     describe Thing do
      #       it "does something" do
      #         described_class == Thing
      #       end
      #     end
      #
      #
      def described_class
        self.class.described_class
      end

      # @private
      # instance_evals the block, capturing and reporting an exception if
      # raised
      def instance_eval_with_rescue(&hook)
        begin
          instance_eval(&hook)
        rescue Exception => e
          raise unless example
          example.set_exception(e)
        end
      end
    end
  end
end
