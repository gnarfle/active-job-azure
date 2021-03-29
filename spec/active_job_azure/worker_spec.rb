require 'spec_helper'

class TestJob
  include ActiveJobAzure::Worker
  azure_queue "test"

  def perform(arg)
    puts arg
  end
end

RSpec.describe ActiveJobAzure::Worker do

end