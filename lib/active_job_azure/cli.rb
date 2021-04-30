require 'rubygems'
require 'json'
require 'yaml'
require 'active_job_azure'
require 'active_job_azure/launcher'
require 'active_job_azure/logger'
require 'active_job_azure/manager'
require 'azure/storage/queue'
require 'active_job'
require 'active_job/queue_adapters/azure_adapter'
require 'optparse'
require 'concurrent'
require 'slop'

module ActiveJobAzure
  class CLI
    include Logging
    attr_accessor :launcher

    def parse_options(args = ARGV)
      opts = option_parser
      options.merge!(opts)
    end

    def run
      if rails_app?
        require "rails"
        require "active_job_azure/rails"
        require File.expand_path('config/application.rb')
        require File.expand_path('config/environment.rb')
      end

      if options[:include]
         require options[:include]
      end

      sigs = %w[INT TERM TTIN TSTP]
      sigs.each do |sig|
        trap sig do
          handle_signal(sig)
        end
      rescue ArgumentError
        log.error "Signal #{sig} not supported"
      end

      @launcher = ActiveJobAzure::Launcher.new(options)

      begin
        launcher.run
      rescue Interrupt
        log.info "Shutting down"
        launcher.stop
        log.info "Bye!"
        exit(0)
      end
    end

    SIGNAL_HANDLERS = {
      # Ctrl-C in terminal
      "INT" => ->(cli) { raise Interrupt },
      # TERM is the signal that Sidekiq must exit.
      # Heroku sends TERM and then waits 30 seconds for process to exit.
      "TERM" => ->(cli) { raise Interrupt },
      "TSTP" => ->(cli) {
        cli.launcher.quiet
      },
      "TTIN" => ->(cli) {
        # Thread.list.each do |thread|
        #   Sidekiq.logger.warn "Thread TID-#{(thread.object_id ^ ::Process.pid).to_s(36)} #{thread.name}"
        #   if thread.backtrace
        #     Sidekiq.logger.warn thread.backtrace.join("\n")
        #   else
        #     Sidekiq.logger.warn "<no backtrace available>"
        #   end
        # end
      }
    }
    UNHANDLED_SIGNAL_HANDLER = ->(cli) { log.info "No signal handler registered, ignoring" }
    SIGNAL_HANDLERS.default = UNHANDLED_SIGNAL_HANDLER

    def handle_signal(sig)
      log.debug "Got #{sig} signal"
      SIGNAL_HANDLERS[sig].call(self)
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
        o.string '-i', '--include', 'include file or directory'
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
