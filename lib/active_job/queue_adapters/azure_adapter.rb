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
        ActiveJobAzure.client.create_message(job.queue_name, JobWrapper.new(job), options)
      end

      class JobWrapper
        attr_accessor :job_data

        def initialize(job)
          @job_data = job.serialize
        end

        def encode(method = "utf-8")
          YAML.dump(self).encode(method)
        end

        def perform
          Base.execute job_data
        end
      end
    end
  end
end