# 1.9 ships with Fibers but we need to require the extra
# methods explicitly. We only load those extra methods if
# Fiber is available in the first place.
require 'fiber' if defined?(Fiber)

module ActionView
  # == TODO
  #
  # * Support streaming from child templates, partials and so on.
  # * Integrate exceptions with exceptron
  # * Rack::Cache needs to support streaming bodies
  class StreamingTemplateRenderer < TemplateRenderer #:nodoc:
    # A valid Rack::Body (i.e. it responds to each).
    # It is initialized with a block that, when called, starts
    # rendering the template.
    class Body #:nodoc:
      def initialize(&start)
        @start = start
      end

      def each(&block)
        begin
          @start.call(block)
        rescue Exception => exception
          log_error(exception)
          block.call ActionView::Base.streaming_completion_on_exception
        end
        self
      end

      private

      # This is the same logging logic as in ShowExceptions middleware.
      # TODO Once "exceptron" is in, refactor this piece to simply re-use exceptron.
      def log_error(exception) #:nodoc:
        logger = ActionController::Base.logger
        return unless logger

        message = "\n#{exception.class} (#{exception.message}):\n"
        message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
        message << "  " << exception.backtrace.join("\n  ")
        logger.fatal("#{message}\n\n")
      end
    end

    # For streaming, instead of rendering a given a template, we return a Body
    # object that responds to each. This object is initialized with a block
    # that knows how to render the template.
    def render_template(template, layout_name = nil, locals = {}) #:nodoc:
      return [super] unless layout_name && template.supports_streaming?

      locals ||= {}
      layout   = layout_name && find_layout(layout_name, locals.keys)

      Body.new do |buffer|
        delayed_render(buffer, template, layout, @view, locals)
      end
    end

    private

    def delayed_render(buffer, template, layout, view, locals)
      # Wrap the given buffer in the StreamingBuffer and pass it to the
      # underlying template handler. Now, everytime something is concatenated
      # to the buffer, it is not appended to an array, but streamed straight
      # to the client.
      output  = ActionView::StreamingBuffer.new(buffer)
      yielder = lambda { |*name| view._layout_for(*name) }

      instrument(:template, :identifier => template.identifier, :layout => layout.try(:virtual_path)) do
        fiber = Fiber.new do
          if layout
            layout.render(view, locals, output, &yielder)
          else
            # If you don't have a layout, just render the thing
            # and concatenate the final result. This is the same
            # as a layout with just <%= yield %>
            output.safe_concat view._layout_for
          end
        end

        # Set the view flow to support streaming. It will be aware
        # when to stop rendering the layout because it needs to search
        # something in the template and vice-versa.
        view.view_flow = StreamingFlow.new(view, fiber)

        # Yo! Start the fiber!
        fiber.resume

        # If the fiber is still alive, it means we need something
        # from the template, so start rendering it. If not, it means
        # the layout exited without requiring anything from the template.
        if fiber.alive?
          content = template.render(view, locals, &yielder)

          # Once rendering the template is done, sets its content in the :layout key.
          view.view_flow.set(:layout, content)

          # In case the layout continues yielding, we need to resume
          # the fiber until all yields are handled.
          fiber.resume while fiber.alive?
        end
      end
    end
  end
end
