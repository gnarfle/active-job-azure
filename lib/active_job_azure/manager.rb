require 'active_job_azure'

if defined?(::Rails) && ::Rails.respond_to?(:application)
  require 'rails'
  require "active_job_azure/rails"
  require File.expand_path('config/application.rb')
  require File.expand_path('config/environment.rb')
end

module ActiveJobAzure
  class Manager
    attr_reader :options

    def initialize(options)
      @options = options
      @done = false
      @pool = Concurrent::ThreadPoolExecutor.new(
        min_threads: 1,
        max_threads: @options[:threads],
        max_queue: 0 # this could never go badly
      )
    end

    def terminate
      return if @done
      @done = true
      puts "Terminating quiet workers"
      @pool.shutdown
      @pool.wait_for_termination(options[:timeout])
    end

    def run
      loop do
        messages = ActiveJobAzure.client.list_messages(options[:queue], options[:retry], {
          number_of_messages: options[:fetch]
        })

        sleep options[:interval] unless options[:interval]

        messages.each do |message|
          @pool.post do
            begin
              job_data = JSON.parse(message.message_text)
              klass = constantize(job_data['class'])
              args = job_data['args']

              worker = klass.new
              worker.perform args

              # seems like this could be bad if the job completes but deleting fails...
              # perhaps we need a retry mechanism for deleting
              ActiveJobAzure.client.delete_message(options[:queue], message.id, message.pop_receipt)
            rescue => e
              # temporary for debugging, we don't want to catch errors here
              # without this jobs silently fail and get retried
              puts e.inspect
            end
          end
        end
      end
    end

    def constantize(str)
      return Object.const_get(str) unless str.include?("::")

      names = str.split("::")
      names.shift if names.empty? || names.first.empty?

      names.inject(Object) do |constant, name|
        # the false flag limits search for name to under the constant namespace
        #   which mimics Rails' behaviour
        constant.const_get(name, false)
      end
    end
  end
end