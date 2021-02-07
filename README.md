# Active::Job::Azure

An ActiveJob adapter and queue worker for azure storage queues.

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

Coming soon

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active-job-azure.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## TODO

1. Handle signals and properly shutting down thread pool
2. Figure out how to handle failures...
3. Make it work without rails
4. Error / Failure handling
5. Logging
6. Tests would be a good idea...

## Strategies

Dealing with job failures will be an issue, perhaps offer various strategies?

1. Set a sufficiently high (configurable) visibility timeout on the message, and on job failure attempt to update the visibility back to 0. If the visibility timeout is 30 seconds or so, then even if the update visibility attempt fails it will come back soon enough. However if a worker takes longer than the timeout for some reason then you could end up with multiple workers working on the same job. Which is not ideal.
2. Delete the message when popping it off the queue, and try to handle failures to put the message back in the queue if the job fails. This is the standard sidekiq approach. The downside is if putting it back into azure queue fails, the job is lost forever. Perhaps a type of journal or log could be used to help.
3. When popping a job off the queue, copy it to a "running job" separate queue. When the job is completed it gets deleted from that queue, and on job failure try to copy it back to the main queue. For a catastrophic failure a worker can scan the running job queue for orphans and re-instate them. This is the sidekiq pro approach. This is the most durable, but likely also the slowest because we're moving jobs around between queues via http calls. It's also the most complex option.

Another issue... If working the job succeeds, but deleting the job from the queue fails, then the job will get re-run. Which is not so good. This also could be handled better by ensuring we delete from the queue before working (strategy 2 above) but then we still have the issue of what if the job fails and re-adding it to the queue fails, now we've lost a job.