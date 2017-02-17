# Sidekiq::InstantlyDead

Sidekiq::InstantlyDead is a server-side Sidekiq middleware.

This plugin provides a way to moving your job to dead set instantly even if retry count remains.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-instantly_dead'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-instantly_dead

## Usage

### configure server middleware settings

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.insert_after Sidekiq::Middleware::Server::RetryJobs, Sidekiq::InstantlyDead::Middleware, max_retries: 5
  end
end
````

- `mas_retries` option
  - default: `Sidekiq::Middleware::Server::RetryJobs::DEFAULT_MAX_RETRY_ATTEMPTS`

### in worker

```ruby
class Worker
  include Sidekiq::Worker
  sidekiq_options retry: 5

  def perform
    # following error raised, move dead set instantly.
    raise Sidekiq::InstantlyDeadError
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dany1468/sidekiq-instantly_dead.

