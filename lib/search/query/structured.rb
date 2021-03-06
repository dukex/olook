module Search
  module Query
    class Structured
      def self.factory
        eval("Search::Query::#{Search::Config.api_version_module_name}::Structured")
      end
      attr_reader :nodes
      def initialize(base_class, operator)
        @base = base_class
        @operator = operator
        @nodes = []
      end

      def field_values
        map_recursively_nodes({}) do |hash, node|
          hash[node.name.to_s] ||= []
          hash[node.name.to_s].push(node.value)
          hash[node.name.to_s].flatten!
        end
      end

      def field(key, value, options={})
        node = create_field(key, value, options)
        @nodes << node
      end

      [:and, :or, :not].each do |m|
        define_method m do |field=nil, value=nil, &block|
          if block
            add_operator_node(m, block)
          else
            add_single_field(m, field, value)
          end
        end
      end

      def map_recursively_nodes(start=nil, &block)
        @nodes.each do |node|
          if node.respond_to?(:name)
            block.call(start, node)
          elsif node.respond_to?(:map_recursively_nodes)
            node.map_recursively_nodes(start, &block)
          end
        end
        start
      end

      def to_url
        raise NotImplementedError.new("You should implement to_url in #{self.class}")
      end

      def query_url
        raise NotImplementedError.new("You should implement query_url in #{self.class}")
      end

      protected

      def url
        @url ||= @nodes.map do |node|
          node.to_url
        end.join(' ')
      end

      def create_field(key, value=nil, options={})
        node = @base.field(key.to_s, options) || Field.factory.new(key, @base, options)
        node.value = value
        node
      end

      def add_operator_node(kind, block)
        if kind == @operator
          block.call(self)
        else
          child_structured = self.class.new(@base, kind)
          block.call(child_structured)
          if child_structured.nodes.size < 2 && kind == @operator
            @nodes.concat child_structured.nodes
          else
            @nodes.push child_structured if child_structured.nodes.size > 0
          end
        end
        self
      end

      def add_single_field(kind, name, value)
        if kind == @operator
          self.field(name, value)
        else
          self.send(kind) do |s|
            s.field name, value
          end
        end
        self
      end
    end
  end
end
