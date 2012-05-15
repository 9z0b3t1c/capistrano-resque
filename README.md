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
cap resque:start     # Start Resque workers
cap resque:stop      # Quit running Resque workers
cap resque:restart   # Restart running Resque workers
```

### Restart on deployer

To restart you workers automatically when `cap deploy:restart` is executed
add the following line to your `deploy.rb`:

```
after "deploy:restart", "resque:restart"
```

