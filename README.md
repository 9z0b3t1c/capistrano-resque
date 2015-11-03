# Capistrano Resque

Basic tasks for putting some Resque in your Cap. This should be fully compatible with both Capistrano 2.x and 3.x,
but if you run into any issues please report them.

At this time, we are only targeting Resque 1.x; the 2.0/master branch is still a work-in-progress without a published gem.

### In your Gemfile:

```ruby
gem "capistrano-resque", "~> 0.2.2", require: false
```

### In lib/tasks:

You'll need to make sure your app is set to include Resque's rake tasks. Per the
[Resque 1.x README](https://github.com/resque/resque/blob/1-x-stable/README.markdown#in-a-rails-3-app-as-a-gem),
you'll need to add `require 'resque/tasks'` somewhere under the `lib/tasks` directory (e.g. in a `lib/tasks/resque.rake` file).

### In your Capfile:

Put this line __after__ any of capistrano's own `require`/`load` statements (specifically `load 'deploy'` for Cap v2):

```ruby
require "capistrano-resque"
```

Note: You must tell Bundler not to automatically require the file (by using `require: false`),
otherwise the gem will try to load the Capistrano tasks outside of the context of running
the `cap` command (e.g. running `rails console`).

### In your deploy.rb:

```ruby
# Specify the server that Resque will be deployed on. If you are using Cap v3
# and have multiple stages with different Resque requirements for each, then
# these __must__ be set inside of the applicable config/deploy/... stage files
# instead of config/deploy.rb:
role :resque_worker, "app_domain"
role :resque_scheduler, "app_domain"

set :workers, { "my_queue_name" => 2 }

# We default to storing PID files in a tmp/pids folder in your shared path, but
# you can customize it here (make sure to use a full path). The path will be
# created before starting workers if it doesn't already exist.
# set :resque_pid_path, -> { File.join(shared_path, 'tmp', 'pids') }

# Uncomment this line if your workers need access to the Rails environment:
# set :resque_environment_task, true
```

You can also specify multiple queues and the number of workers
for each queue:

```ruby
set :workers, { "archive" => 1, "mailing" => 3, "search_index, cache_warming" => 1 }
```

The above will start five workers in total:

 * one listening on the `archive` queue
 * one listening on the `search_index, cache_warming` queue
 * three listening on the `mailing` queue

If you need to pass arbitrary data (like other non-standard environment variables) to the "start" command, you can specify:

```ruby
set :resque_extra_env, "SEARCH_SERVER=172.18.0.52"
```

This can be useful for customizing Resque tasks in complex server environments.

### Multiple Servers/Roles

You can also start up workers on multiple servers/roles:

```ruby
role :worker_server_A,  <server-ip-A>
role :worker_servers_B_and_C,  [<server-ip-B>, <server-ip-C>]

set :workers, {
  worker_server_A: {
    "archive" => 1,
    "mailing" => 1
  },
  worker_servers_B_and_C: {
    "search_index" => 1,
  }
}
```

The above will start four workers in total:

 * one `archive` on Server A
 * one `mailing` on Server A
 * one `search_index` on Server B
 * one `search_index` on Server C

### Rails Environment

With Rails, Resque requires loading the Rails environment task to have access to your models, etc. (e.g. `QUEUE=* rake environment resque:work`). However, Resque is often used without Rails (and even if you are using Rails, you may not need/want to load the Rails environment). As such, the `environment` task is not automatically included.

If you would like to load the `environment` task automatically, add this to your `deploy.rb`:

```ruby
set :resque_environment_task, true
```

If you would like your workers to use a different Rails environment than your actual Rails app:

```ruby
set :resque_rails_env, "my_resque_env"
```

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

```ruby
after "deploy:restart", "resque:restart"
```

### Logging

Backgrounding and logging are current sticking points. I'm using the HEAD of resque's 1-x-stable branch for the 0.0.8 release because it has some new logging functions not yet slated for a resque release.

In your Gemfile, you will need to specify:

```ruby
gem 'resque', :git => 'git://github.com/resque/resque.git', :branch => '1-x-stable'
```

Also, you will need to include:

```ruby
Resque.logger = Logger.new("new_resque_log_file")
```

...somewhere sensible, such as in your resque.rake, to achieve logging.

The chatter on: https://github.com/defunkt/resque/pull/450 gives more information. If using HEAD of this resque branch doesn't work for you, then pin to v0.0.7 of this project.

### Redirecting output

Due to issues in the way Resque 1.x handles background processes, we automatically redirect stderr and stdout to `/dev/null`.

If you'd like to capture this output instead, just specify a log file:

```ruby
set :resque_log_file, "log/resque.log"
```

You can also disable the `VERBOSE` option to reduce the amount of log output:

```ruby
set :resque_verbose, false
```

### Limitations

Starting workers is done concurrently via Capistrano and you are limited by ssh connections limit on your server (default limit is 10)

To to use more workers, please change your sshd configuration (/etc/ssh/sshd_config)

    MaxStartups 100


### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. If possible, make sure your changes apply to both the Capistrano v2 and v3 code (`capistrano_integration.rb` is v2, `capistrano-resque.rake` is v3)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

### License

Please see the included LICENSE file.
