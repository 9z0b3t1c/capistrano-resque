# 0.2.3 and newer
* Please see the [Github Releases](https://github.com/sshingler/capistrano-resque/releases) page for changelog info

# 0.2.2
* Start all background tasks with `nohup` to avoid `SIGHUP` problems
* Add a `:resque_verbose` option to toggle verbose output (defaults to `true`)

# 0.2.1
* Create the directory for pid files when it doesn't exist
* Default pid files to `#{shared_path}/tmp/pids` now
* Added a `:resque_pid_path` option to specify a custom path

# 0.2.0
* Added support for Capistrano 3.0
* Set MUTE environment variable for resque_scheduler
* Added a `resque_environment_task` option to load the `environment` rake task before running Resque workers
* Add a resque:scheduler:status task
* Detect stale PID files and clean up instead of aborting
* Add a `resque_rails_env` setting in case workers need to be run in a different environment than the app itself

# 0.1.0
* Interval is configurable
* Fix issue where pids weren't created correctly

# 0.0.9
* Start workers in threads

# 0.0.8
* Using stable branch of Resque, rather than the released gem, to take advantage of logging ability, losing shell redirection
* Using SIGQUIT to kill processes as they aren't terminating properly

# 0.0.7
* Different workers for different roles
