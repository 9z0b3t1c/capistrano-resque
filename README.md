# Capistrano Resque

Basic tasks for putting some Resque in your Cap.

### In your Capfile:

```
require "capistrano-resque"
```

### In your deploy.rb:

```
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
cap resque:start_workers     # Start Resque workers
cap resque:stop_workers      # Quit running Resque workers
```
