require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'active_job_azure/rails' if defined?(::Rails::Engine)
require 'concurrent'
require 'azure/storage/queue'
require 'active_job_azure/worker'
require 'active_job_azure/typhoeus_client'
require 'logger'

module ActiveJobAzure
  DEFAULTS = {
    threads: Concurrent.processor_count,
    fetch: 32,   # how many jobs to fetch at once, max 32
    retry: 30,   # how long to "hide" jobs in azure while they are being worked
    timeout: 30, # time to wait for jobs to finish on shutdown
    interval: 0  # how long to pause when fetching jobs from azure
  }

  def self.options
    @options ||= DEFAULTS.dup
  end

  def self.options=(opts)
    @options = opts
  end

  def self.configure
    yield self
  end

  # could also be ENV['AZURE_STORAGE_ACCOUNT']
  def self.storage_account_name
    @storage_account_name
  end

  def self.storage_account_name=(name)
    @storage_account_name = name
  end

  # could also be ENV['AZURE_STORAGE_ACCESS_KEY]
  def self.storage_account_key
    @storage_account_key
  end

  def self.storage_account_key=(key)
    @storage_account_key = key
  end

  # could also be ENV['AZURE_STORAGE_CONNECTION_STRING']
  def self.storage_connection_string
    @storage_connection_string
  end

  def self.storage_connection_string=(str)
    @storage_connection_string = str
  end

  def self.client
    opts = {}

    if @storage_connection_string
      opts[:storage_connection_string] = @storage_connection_string
    elsif @storage_account_name && @storage_account_key
      opts[:storage_account_name] = @storage_account_name
      opts[:storage_account_key] = @storage_account_key
    end

    http_client = ActiveJobAzure::TyphoeusClient.create(opts)
    @client ||= Azure::Storage::Queue::QueueService.new(client: http_client)
  rescue Exception => e
    puts e.message
    exit
  end

  def self.logger
    @logger ||= Logger.new($stdout, level: Logger::INFO)
  end
end