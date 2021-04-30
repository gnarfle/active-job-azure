require 'active_job_azure/logger'

module ActiveJobAzure
  module Worker
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Logging
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

        log.debug("Enqueueing job to #{queue_name} with #{job_args} and options: #{options}")

        message_object = ActiveJobAzure.client.create_message(
          queue_name,
          job_args.to_json,
          options
        )

        log.info(message_object)
      end
    end
  end
end