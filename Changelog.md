# Unreleased
* Added support for Capistrano 3.0
* Set MUTE environment variable for resque_scheduler
* Added a `resque_environment_task` option to load the `environment` rake task before running Resque workers
* Add a resque:scheduler:status task

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
