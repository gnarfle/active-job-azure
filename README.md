# Active::Job::Azure

An ActiveJob adapter and queue worker for azure storage queues. Also works without ActiveJob!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active-job-azure'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install active-job-azure

## Usage

This gem can be used in a standalone ruby class or as part of ActiveJob in rails.

Either way, you will first need to create the queue before adding jobs:

```
bundle exec azure-queue-worker --create test-queue
```

### Standalone Ruby

Create a worker class and include the Worker class. Your worker must define a
perform method, and define the queue name with `azure_queue`. A simple example:

```
class TestJob
  include ActiveJobAzure::Worker
  azure_queue "test-queue"

  def perform(arg)
    puts "running job #{arg}"
  end
end
```

### ActiveJob

Configure active job to use the azure adapter in `config/application.rb`

```
config.active_job.queue_adapter = :azure
```

Create a worker in app/jobs:

```
class TestJob < ApplicationJob
  queue_as 'test-queue'

  def perform(id)
    puts "just ran job #{id}"
  end
end
```

### Running the queue worker

The queue worker will process jobs against a specific queue. If you need to work
multiple queues, you will need to start multiple workers. Using something like
bluepill, god or foreman to manage this is recommended.

To work jobs in test-queue, run:

```
bundle exec azure-queue-worker -q test-queue
```

The full options can be listed with `--help`:

```
Usage:
	 azure_queue_worker -q queue-name [OPTIONS]
	 azure_queue_worker --empty queue-name
	 azure_queue_worker --delete queue-name
	 azure_queue_worker --create queue-name

    -q, --queue        azure queue name
    -c, --concurrency  number of threads
    -f, --fetch        number of jobs to fetch per azure call
    -r, --retry        retry interval (in seconds)
    -i, --include      include file or directory
    -e, --empty        empty queue [NAME] (cannot be undome!)
    -d, --delete       delete queue [NAME] (cannot be undone!)
    --interval         how often we call azure
    --create           create queue [NAME]
    --version          print version
    --help             print help
```

A few important options:

* `concurrency`: Defaults to the number of processor cores, this defines the number of threads used to work jobs
* `fetch`: The number of jobs we fetch from azure per http call. The max azure supports is 32, the default for the gem is 20. Because there is some latency in http calls to azure, fetching more per api call is probably better.
* `retry`: This is the amount of time we "hide" jobs in azure queues when we fetch them (see discussion below)
* `include`: If you are running outside of rails you want to use this to include your worker class or app code. Example `bundle exec azure-queue-worker -q test-queue -i ./my_worker.rb`
* `interval`: The minimum amount of time we wait before azure api calls. This value can be used to throttle how often you call azure if you are concerned about rate limiting. For example, a value of 5 would mean we don't call azure more often than once every 5 seconds. A value of 0 (default) means we call azure for more jobs as soon as we finish working the current batch.

## Development

## How it works

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active-job-azure.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## TODO

1. Handle signals and properly shutting down thread pool
2. Figure out how to handle failures...
3. ~Make it work without rails~
4. Error / Failure handling
5. Logging
6. Tests would be a good idea...
7. Expontential retry
8. Polling frequency
9. Multiple queue support?
10. Retry tracking and max retries

## Strategies

Dealing with job failures will be an issue, perhaps offer various strategies?

1. Set a sufficiently high (configurable) visibility timeout on the message, and on job failure attempt to update the visibility back to 0. If the visibility timeout is 30 seconds or so, then even if the update visibility attempt fails it will come back soon enough. However if a worker takes longer than the timeout for some reason then you could end up with multiple workers working on the same job. Which is not ideal.
2. Delete the message when popping it off the queue, and try to handle failures to put the message back in the queue if the job fails. This is the standard sidekiq approach. The downside is if putting it back into azure queue fails, the job is lost forever. Perhaps a type of journal or log could be used to help.
3. When popping a job off the queue, copy it to a "running job" separate queue. When the job is completed it gets deleted from that queue, and on job failure try to copy it back to the main queue. For a catastrophic failure a worker can scan the running job queue for orphans and re-instate them. This is the sidekiq pro approach. This is the most durable, but likely also the slowest because we're moving jobs around between queues via http calls. It's also the most complex option.

Another issue... If working the job succeeds, but deleting the job from the queue fails, then the job will get re-run. Which is not so good. This also could be handled better by ensuring we delete from the queue before working (strategy 2 above) but then we still have the issue of what if the job fails and re-adding it to the queue fails, now we've lost a job.