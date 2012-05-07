# Capistrano Resque

Basic tasks for putting some Resque in your Cap.

### In your Capfile:

```
require "capistrano-resque"
```

### In your deploy.rb:

```
set :queue_name, "my_queue_name"
set :num_of_queues, 2
```

Then, running cap -vT | grep resque should give you...

```
➔ cap -vT | grep resque
cap resque:start_workers     # Start Resque workers
cap resque:stop_workers      # Quit running Resque workers
```