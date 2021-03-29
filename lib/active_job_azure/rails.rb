require "active_job_azure/worker"

module ActiveJobAzure
  class Rails < ::Rails::Engine
    config.before_configuration do
      if defined?(::ActiveJob)
        require 'active_job/queue_adapters/azure_adapter'
      end
    end
  end
end