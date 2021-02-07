require 'active_job_azure/rails' if defined?(::Rails::Engine)
require 'concurrent'
require 'dotenv/load'

module ActiveJobAzure
  DEFAULTS = {
    threads: Concurrent.processor_count,
    fetch: 20,
    retry: 30
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
    if @storage_account_name && @storage_account_key
      opts[:storage_account_name] = @storage_account_name
      opts[:storage_account_key] = @storage_account_key
    elsif @storage_connection_string
      opts[:storage_connection_string] = @storage_connection_string
    end
    @client ||= ::Azure::Storage::Queue::QueueService.create(opts)
  rescue Azure::Storage::Common::InvalidOptionsError => e
    puts "Invalid connection details"
    exit
  end
end