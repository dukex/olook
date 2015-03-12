module Abacos
  class IntegrateProductsObserver
    @queue = 'low'
    class << self
      def perform opts
        @opts = opts
        integration_finished? ? notify : schedule_notification
      end


      def products_to_be_integrated products_amount
        REDIS.set("products_to_integrate", products_amount)
      end

      def mark_product_integrated_as_success!
        decrement_products_to_be_integrated!
      end

      def mark_product_integrated_as_failure!(product_number, error_message)
        decrement_products_to_be_integrated!
        REDIS.mapped_hmset("integration_errors", { "#{ product_number }" => "#{ error_message }" })
      end

      private
        def decrement_products_to_be_integrated!
          REDIS.decrby("products_to_integrate", 1)
        end

        def integration_finished?
          REDIS.get("products_to_integrate").to_i.zero?
        end

        def notify
          opts = HashWithIndifferentAccess.new(@opts)
          user = opts["user"]
          products_amount = opts["products_amount"]
          if Setting.reschedule_integrate_products_if_qty_gt_1000 && products_amount.to_i > 1000
            Resque.enqueue(Abacos::IntegrateProducts, user)
          end
          IntegrationProductsAlert.notify(user, products_amount, products_errors)
          clean_products_errors
        end

        def products_errors
          REDIS.hgetall("integration_errors")
        end

        def clean_products_errors
          REDIS.del("integration_errors")
        end

        def schedule_notification
          Resque.enqueue_in(5.minutes, self, @opts)
        end
    end
  end
end
