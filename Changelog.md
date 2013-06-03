# unreleased
# set variable raise_on_resque_stop to true if you want the resque:stop task to break the task chain execution,
# leave as default or set explicitly to false in order to allow task chain execution to continue
# e.g.
# * executing `resque:stop'
# * executing "if [ -e /whatever/current/tmp/pids/resque_work_1.pid ]; then for f in `ls /whatever/current/tmp/pids/resque_work*.pid`; do kill -s QUIT `cat $f` && rm $f ;done;fi"
# servers: ["foo.com"]
# [foo.com] executing command
# *** [err :: foo.com] sh: line 0: kill: (1234) - No such process
# command finished in 1234ms
# failed: "sh -c 'if [ -e /whatever/current/tmp/pids/resque_work_1.pid ]; then for f in `ls /whatever/current/tmp/pids/resque_work*.pid`; do kill -s QUIT `cat $f` && rm $f ;done;fi'" on foo.com


# 0.1.0
Interval is configurable
Fix issue where pids weren't created correctly

# 0.0.9

Start workers in threads

# 0.0.8

Using stable branch of Resque, rather than the released gem, to take advantage of logging ability, losing shell redirection
Using SIGQUIT to kill processes as they aren't terminating properly


# 0.0.7

Different workers for different roles
