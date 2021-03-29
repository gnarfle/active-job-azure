class ActiveJobAzure::Launcher
  # launcher manages the poller and manager processes to coordinate
  # fetching job and passing them to workers
  attr_accessor :manager

  def initialize(options)
    @manager = ActiveJobAzure::Manager.new(options)
    @done = false
    @options = options
  end

  def run
    @manager.run
  end

  def quiet
    @done = true
    @manager.terminate
  end

  def stop
    @done = true
    @manager.terminate
  end
end