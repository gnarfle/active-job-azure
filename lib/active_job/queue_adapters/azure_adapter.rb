# frozen_string_literal: true

require 'active_job'
require 'azure/storage/queue'
require 'active_job_azure'

module ActiveJob
  module QueueAdapters
    class AzureAdapter
      def enqueue(job)
        enqueue_at(job, nil)
      end

      def enqueue_at(job, timestamp)
        options = {}
        if timestamp
          delay = timestamp - Time.now.to_i
          options['visibility_timeout'] = delay # todo - make sure not too big? max 7 days
        end

        job_args = {
          class: JobWrapper,
          wrapped: job.class,
          args: [ job.serialize ]
        }

        ActiveJobAzure.client.create_message(
          job.queue_name,
          job_args.to_json,
          options
        )
      end

      class JobWrapper
        include ActiveJobAzure::Worker

        def perform
          Base.execute job_data
        end
      end
    end
  end
end