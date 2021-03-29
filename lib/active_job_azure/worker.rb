module ActiveJobAzure
  module Worker
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_reader :queue_name

      def azure_queue(name)
        @queue_name = name
      end

      def perform_async(*args)
        azure_push(args)
      end

      # +interval+ must be a timestamp, numeric or something that acts
      #   numeric (like an activesupport time interval).
      def perform_in(interval, *args)
        int = interval.to_f
        azure_push(args, int)
      end
      alias_method :perform_at, :perform_in

      private

      def azure_push(args, delay = nil)
        job_args = {
          class: self,
          args: args
        }

        options = {}
        if delay
          options['visibility_timeout'] = delay # todo - make sure not too big? max 7 days
        end

        ActiveJobAzure.client.create_message(
          queue_name,
          job_args.to_json,
          options
        )
      end
    end
  end
end