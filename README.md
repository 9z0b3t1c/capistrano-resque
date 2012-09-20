# Capistrano Resque

Basic tasks for putting some Resque in your Cap.

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
cao resque:status    # Check worksers status
cap resque:start     # Start Resque workers
cap resque:stop      # Quit running Resque workers
cap resque:restart   # Restart running Resque workers
cap resque:scheduler:restart # 
cap resque:scheduler:start   # Starts resque scheduler with default configs
cap resque:scheduler:stop    # Stops resque scheduler
```

### Restart on deployment

To restart you workers automatically when `cap deploy:restart` is executed
add the following line to your `deploy.rb`:

```
after "deploy:restart", "resque:restart"
```
### Logging

I've decided to lose the logging ability altogether, in order to keep up with recent versions of Resque, following the chatter on: https://github.com/defunkt/resque/pull/450

If logging is important to you, there's still the 0.0.4 release of this project.

### License

Please see the included LICENSE file.
