namespace :load do
  task :defaults do
    set :workers, {"*" => 1}
    set :resque_kill_signal, "QUIT"
    set :interval, "5"
    set :resque_environment_task, false
    set :worker_log_folder, "./log"
    set :worker_pid_folder, "./tmp/pids"
  end
end

namespace :resque do
  def workers_roles
    return fetch(:workers).keys if fetch(:workers).first[1].is_a? Hash
    [:resque_worker]
  end

  def for_each_workers(&block)
    if fetch(:workers).first[1].is_a? Hash
      workers_roles.each do |role|
        yield(role.to_sym, fetch(:workers)[role.to_sym])
      end
    else
      yield(:resque_worker, fetch(:workers))
    end
  end

  #check if the pid inside the pid file is an existing process, and only then kill it
  def kill_process_if_running(pid_file)
    pid_exists = capture(:if,"ps -A -o pid | grep $(cat #{pid_file.chomp}) > /dev/null; then echo 'exists'; else echo 'not exists'; fi")
    if test "[ '#{pid_exists}' = 'exists' ]"
      execute :kill, "-s #{fetch(:resque_kill_signal)} $(cat #{pid_file.chomp})"
    end
  end

  desc "See current worker status"
  task :status do
    on roles(*workers_roles) do
      if test "[ -e #{fetch(:worker_pid_folder)}/resque_work_1.pid ]"
        within current_path do
          files = capture(:ls, "-1 #{fetch(:worker_pid_folder)}/resque_work*.pid")
          files.each_line do |file|
            info capture(:ps, "-f -p $(cat #{file.chomp}) | sed -n 2p")
          end
        end
      end
    end
  end

  desc "Start Resque workers"
  task :start do
    for_each_workers do |role, workers|
      on roles(role) do
        worker_id = 1
        workers.each_pair do |queue, number_of_workers|
          info "Starting #{number_of_workers} worker(s) with QUEUE: #{queue}"
          number_of_workers.times do
            pid = "#{fetch(:worker_pid_folder)}/resque_work_#{worker_id}.pid"
            log = "#{fetch(:worker_log_folder)}/resque_work_#{worker_id}.log"
            within current_path do
              execute :rake, %{RAILS_ENV=#{fetch(:rails_env)} QUEUE="#{queue}" PIDFILE=#{pid} BACKGROUND=yes VERBOSE=1 INTERVAL=#{fetch(:interval)} #{"environment" if fetch(:resque_environment_task)} resque:work >> #{log}}
            end
            worker_id += 1
          end
        end
      end
    end
  end

  # See https://github.com/defunkt/resque#signals for a descriptions of signals
  # QUIT - Wait for child to finish processing then exit (graceful)
  # TERM / INT - Immediately kill child then exit (stale or stuck)
  # USR1 - Immediately kill child but don't exit (stale or stuck)
  # USR2 - Don't start to process any new jobs (pause)
  # CONT - Start to process new jobs again after a USR2 (resume)
  desc "Quit running Resque workers"
  task :stop do
    on roles(*workers_roles) do
      number_of_pid_files = capture(:ls,"-l #{fetch(:worker_pid_folder)}/resque_work*.pid 2> /dev/null | wc -l")
      if test "[ #{number_of_pid_files} -gt 0 ]"
        within current_path do
          pids = capture(:ls, "-1 #{fetch(:worker_pid_folder)}/resque_work*.pid")
          pids.each_line do |pid_file|
            kill_process_if_running(pid_file)
            execute "rm #{pid_file.chomp}"
          end
        end
      end
    end
  end

  desc "Restart running Resque workers"
  task :restart do
    invoke "resque:stop"
    invoke "resque:start"
  end

  namespace :scheduler do
    desc "See current scheduler status"
    task :status do
      on roles :resque_scheduler do
        pid = "#{current_path}/tmp/pids/scheduler.pid"
        if test "[ -e #{pid} ]"
          info capture(:ps, "-f -p $(cat #{pid}) | sed -n 2p")
        end
      end
    end

    desc "Starts resque scheduler with default configs"
    task :start do
      on roles :resque_scheduler do
        pid = "#{current_path}/tmp/pids/scheduler.pid"
        within current_path do
          execute :rake, %{RAILS_ENV=#{fetch(:rails_env)} PIDFILE=#{pid} BACKGROUND=yes VERBOSE=1 MUTE=1 resque:scheduler}
        end
      end
    end

    desc "Stops resque scheduler"
    task :stop do
      on roles :resque_scheduler do
        pid = "#{current_path}/tmp/pids/scheduler.pid"
        if test "[ -e #{pid} ]"
          execute :kill, "-s #{fetch(:resque_kill_signal)} $(cat #{pid}); rm #{pid}"
        end
      end
    end

    task :restart do
      invoke "resque:scheduler:stop"
      invoke "resque:scheduler:start"
    end
  end
end

