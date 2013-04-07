# Capistrano Resque

Basic tasks for putting some Resque in your Cap.

### In your Gemfile:

```
gem "capistrano-resque", "~> 0.1.0"
```

### In your Capfile:

```
require "capistrano-resque"
```

### In your deploy.rb:

```
role :resque_worker, "app_domain"
role :resque_scheduler, "app_domain"

set :workers, { "my_queue_name" => 2 }
```

You can also specify multiple queues and the number of workers
for each queue:

```
set :workers, { "archive" => 1, "mailing" => 3, "search_index, cache_warming" => 1 }
```

The above will start five workers in total:

 * one listening on the `archive` queue
 * one listening on the `search_index, cache_warming` queue
 * three listening on the `mailing` queue

### The tasks

Running cap -vT | grep resque should give you...

```
➔ cap -vT | grep resque
cap resque:status    # Check workers status
cap resque:start     # Start Resque workers
cap resque:stop      # Quit running Resque workers
cap resque:restart   # Restart running Resque workers
cap resque:scheduler:restart #
cap resque:scheduler:start   # Starts Resque Scheduler with default configs
cap resque:scheduler:stop    # Stops Resque Scheduler
```

### Restart on deployment

To restart you workers automatically when `cap deploy:restart` is executed
add the following line to your `deploy.rb`:

```
after "deploy:restart", "resque:restart"
```
### Logging

Backgrounding and logging are current sticking points. I'm using the HEAD of resque's 1-x-stable branch for the 0.0.8 release because it has some new logging functions not yet slated for a resque release.

In your Gemfile, you will need to specify:

```
gem 'resque', :git => 'git://github.com/resque/resque.git', :branch => '1-x-stable'
```

Also, you will need to include:

```
Resque.logger = Logger.new("new_resque_log_file")
```

...somewhere sensible, such as in your resque.rake, to achieve logging.

The chatter on: https://github.com/defunkt/resque/pull/450 gives more information. If using HEAD of this resque branch doesn't work for you, then pin to v0.0.7 of this project.

### Limitations

Starting workers is done concurently via capistrano and you are limited by ssh connections limit on your server (default limit is 10)

in order to use more workers please change your sshd configurtion (/etc/ssh/sshd_config)

    MaxStartups 100


### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### License

Please see the included LICENSE file.
