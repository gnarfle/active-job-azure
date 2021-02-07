require 'active_job_azure'
require 'rails'
require "active_job_azure/rails"
require File.expand_path('config/application.rb')
require File.expand_path('config/environment.rb')

module ActiveJobAzure
  class Manager
    attr_reader :options

    def initialize(options)
      @options = options
      @pool = Concurrent::ThreadPoolExecutor.new(
        min_threads: 1,
        max_threads: @options[:threads],
        max_queue: 0 # this could never go badly
      )
    end

    def run
      loop do
        messages = ActiveJobAzure.client.list_messages(options[:queue], options[:retry], {
          number_of_messages: options[:fetch]
        })
        sleep 1 and next if messages.empty?
        messages.each do |message|
          @pool.post do
            begin
              job = YAML.load(message.message_text)
              job.perform
              # seems like this could be bad if the job completes but deleting fails...
              # perhaps we need a retry mechanism for deleting
              ActiveJobAzure.client.delete_message(options[:queue], message.id, message.pop_receipt)
            rescue StandardError => e
              # temporary for debugging, we don't want to catch errors here
              # without this jobs silently fail and get retried
              puts e.inspect
              raise e
            end
          end
        end
      end
    end
  end
end