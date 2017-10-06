namespace :load do
  task :defaults do
    set :workers, {"*" => 1}
    set :resque_extra_env, ""
    set :resque_kill_signal, "QUIT"
    set :interval, "5"
    set :resque_environment_task, false
    set :resque_log_file, "/dev/null"
    set :resque_verbose, true
    set :resque_pid_path, -> { File.join(shared_path, 'tmp', 'pids') }
    set :resque_dynamic_schedule, false
  end
end

namespace :resque do
  def rails_env
    fetch(:resque_rails_env) ||
      fetch(:rails_env) ||       # capistrano-rails doesn't automatically set this (yet),
      fetch(:stage)              # so we need to fall back to the stage.
  end

  def output_redirection
    ">> #{fetch(:resque_log_file)} 2>> #{fetch(:resque_log_file)}"
  end

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

  def create_pid_path
    if !(test "[ -d #{fetch(:resque_pid_path)} ]")
      info "Creating #{fetch(:resque_pid_path)}"
      execute :mkdir, "-p #{fetch(:resque_pid_path)}"
    end
  end

  desc "See current worker status"
  task :status do
    on roles(*workers_roles) do
      if test "[ -e #{fetch(:resque_pid_path)}/resque_work_1.pid ]"
        within current_path do
          files = capture(:ls, "-1 #{fetch(:resque_pid_path)}/resque_work*.pid")
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
        create_pid_path
        worker_id = 1
        workers.each_pair do |queue, number_of_workers|
          info "Starting #{number_of_workers} worker(s) with QUEUE: #{queue}"
          number_of_workers.times do
            pid = "#{fetch(:resque_pid_path)}/resque_work_#{worker_id}.pid"
            within current_path do
              execute :env, %{#{fetch(:resque_extra_env)} #{SSHKit.config.command_map[:rake]} RACK_ENV=#{rails_env} RAILS_ENV=#{rails_env} QUEUE="#{queue}" PIDFILE=#{pid} BACKGROUND=yes #{"VERBOSE=1 " if fetch(:resque_verbose)}INTERVAL=#{fetch(:interval)} #{"environment " if fetch(:resque_environment_task)}resque:work #{output_redirection}}
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
      if test "[ -e #{fetch(:resque_pid_path)}/resque_work_1.pid ]"
        within current_path do
          pids = capture(:ls, "-1 #{fetch(:resque_pid_path)}/resque_work*.pid").lines.map(&:chomp)
          pids.each do |pid_file|
            pid = capture(:cat, pid_file)
            if test "kill -0 #{pid} > /dev/null 2>&1"
              execute :kill, "-s #{fetch(:resque_kill_signal)} #{pid} && rm #{pid_file}"
            else
              info "Process #{pid} from #{pid_file} is not running, cleaning up stale PID file"
              execute :rm, pid_file
            end
          end
        end
      else
        info "No resque PID files found"
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
        pid = "#{fetch(:resque_pid_path)}/scheduler.pid"
        if test "[ -e #{pid} ]"
          info capture(:ps, "-f -p $(cat #{pid}) | sed -n 2p")
        end
      end
    end

    desc "Starts resque scheduler with default configs"
    task :start do
      on roles :resque_scheduler do
        create_pid_path
        pid = "#{fetch(:resque_pid_path)}/scheduler.pid"
        within current_path do
          execute :env, %{#{fetch(:resque_extra_env)} #{SSHKit.config.command_map[:rake]} RACK_ENV=#{rails_env} RAILS_ENV=#{rails_env} PIDFILE=#{pid} BACKGROUND=yes #{"VERBOSE=1 " if fetch(:resque_verbose)}MUTE=1 #{"DYNAMIC_SCHEDULE=yes " if fetch(:resque_dynamic_schedule)}#{"environment " if fetch(:resque_environment_task)}resque:scheduler #{output_redirection}}
        end
      end
    end

    desc "Stops resque scheduler"
    task :stop do
      on roles :resque_scheduler do
        pid = "#{fetch(:resque_pid_path)}/scheduler.pid"
        if test "[ -e #{pid} ]"
          execute :kill, "-s #{fetch(:resque_kill_signal)} $(cat #{pid}); rm #{pid}"
        end
      end
    end

    desc "Restart resque scheduler"
    task :restart do
      invoke "resque:scheduler:stop"
      invoke "resque:scheduler:start"
    end
  end
end
