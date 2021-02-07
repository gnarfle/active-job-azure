require 'rubygems'
require 'json'
require 'yaml'
require 'active_job_azure'
require 'active_job_azure/manager'
require 'azure/storage/queue'
require 'active_job'
require 'active_job/queue_adapters/azure_adapter'
require 'optparse'
require 'concurrent'
require 'slop'

module ActiveJobAzure
  class CLI

    def parse_options(args = ARGV)
      opts = option_parser
      options.merge!(opts)
    end

    def run
      if rails_app?
        require "active_job_azure/rails"
        require 'rails'
        require File.expand_path('config/application.rb')
        require File.expand_path('config/environment.rb')
      end

      puts "Azure Queue Worker reporting for duty"
      ActiveJobAzure::Manager.new(options).run
      # loop do
      #   messages = client.list_messages(options[:queue], options[:fetch])
      #   sleep 1 and next if messages.empty?
      #   messages.each do |message|
      #     job = YAML.load(message.message_text)
      #     job.perform
      #     client.delete_message(options[:queue], message.id, message.pop_receipt)
      #   end
      # end
    end

    def options
      ActiveJobAzure.options
    end

    def client
      ActiveJobAzure.client
    end

    def option_parser
      opts = Slop.parse do |o|
        o.banner = <<~USAGE
          Usage:
          \t azure_queue_worker -q queue-name [OPTIONS]
          \t azure_queue_worker --empty queue-name
          \t azure_queue_worker --delete queue-name
          \t azure_queue_worker --create queue-name
        USAGE
        o.string '-q', '--queue', 'azure queue name', required: true
        o.integer '-c', '--concurrency', 'number of threads', default: ActiveJobAzure::DEFAULTS['concurrency']
        o.integer '-f', '--fetch', 'number of jobs to fetch per azure call', default: 20
        o.integer '-r', '--retry', 'retry interval (in seconds)', default: 30
        o.on '-e', '--empty', 'empty queue [NAME] (cannot be undome!)' do
          clear_queue
        end
        o.on '-d', '--delete', 'delete queue [NAME] (cannot be undone!)' do
          delete_queue
        end
        o.on '--create', 'create queue [NAME]' do
          create_queue
        end
        o.on '--version', 'print version' do
          puts "ActiveJobAzure #{ActiveJobAzure::VERSION}"
          exit(0)
        end
        o.on '--help', 'print help' do
          puts o
          exit
        end
      end
      opts.to_hash
    rescue Slop::Error => e
      puts e.message
      exit(0)
    end

    def clear_queue
      puts "Please supply the queue name to empty" and die unless ARGV.count == 2
      begin
        queue = ARGV[1]
        count, meta = client.get_queue_metadata queue
        print "Are you sure you want to clear #{count} messages? (yes/no): "
        input = STDIN.gets.chomp
        puts "Aborting!" and exit unless input[0].downcase == 'y'
        client.clear_messages queue
        puts "Deleted #{count} messages successfully"
      rescue Azure::Core::Http::HTTPError => e
        puts e.description
      ensure
        exit
      end
    end

    def delete_queue
      puts "Please supply the queue name to empty" and die unless ARGV.count == 2
      begin
        queue = ARGV[1]
        client.delete_queue queue
        puts "Deleted #{queue} successfully"
      rescue Azure::Core::Http::HTTPError => e
        puts e.description
      ensure
        exit
      end
    end

    def create_queue
      puts "Please supply the queue name to empty" and die unless ARGV.count == 2
      begin
        queue = ARGV[1]
        client.create_queue queue
        puts "Crated #{queue} successfully"
      rescue Azure::Core::Http::HTTPError => e
        puts e.description
      ensure
        exit
      end
    end

    def rails_app?
      defined?(::Rails) && ::Rails.respond_to?(:application)
    end
  end
end
