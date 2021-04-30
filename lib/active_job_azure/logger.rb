module ActiveJobAzure
  module Logging
    # Proxy method to the singleton logger instance
    def log
      ActiveJobAzure.logger
    end
  end
end