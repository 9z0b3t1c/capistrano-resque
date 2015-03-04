require "capistrano"
require "capistrano/version"

module CapistranoResque
  class CapistranoIntegration
    def self.load_into(capistrano_config)
      capistrano_config.load do

        _cset(:workers, {"*" => 1})
        _cset(:resque_kill_signal, "QUIT")
        _cset(:interval, "5")
        _cset(:resque_environment_task, false)
        _cset(:resque_log_file, "/dev/null")
        _cset(:resque_verbose, true)
        _cset(:resque_pid_path) { File.join(shared_path, 'tmp', 'pids') }
        _cset(:enable_shared_users, false)

        def rails_env
          fetch(:resque_rails_env, fetch(:rails_env, "production"))
        end

        def maybe_sudo
          !!fetch(:enable_shared_users) ? try_sudo : ''
        end

        def output_redirection
          ">> #{fetch(:resque_log_file)} 2>> #{fetch(:resque_log_file)}"
        end

        def workers_roles
          return workers.keys if workers.first[1].is_a? Hash
          [:resque_worker]
        end

        def for_each_workers(&block)
          if workers.first[1].is_a? Hash
            workers_roles.each do |role|
              yield(role.to_sym, workers[role.to_sym])
            end
          else
            yield(:resque_worker,workers)
          end
        end

        def run_and_rescue(command)
          run(command)
          true
        rescue Capistrano::CommandError
          false
        end

        def status_command
          "if [ -e #{fetch(:resque_pid_path)}/resque_work_1.pid ]; then \
            for f in $(ls #{fetch(:resque_pid_path)}/resque_work*.pid); \
              do ps -p $(cat $f) | sed -n 2p ; done \
           ;fi"
        end

        def start_command(queue, pid)
          "cd #{current_path} && RAILS_ENV=#{rails_env} QUEUE=\"#{queue}\" \
           PIDFILE=#{pid} BACKGROUND=yes \
           #{"VERBOSE=1 " if fetch(:resque_verbose)}\
           INTERVAL=#{interval} \
           nohup #{fetch(:bundle_cmd, "bundle")} exec rake \
           #{"environment " if fetch(:resque_environment_task)}\
           resque:work #{output_redirection}"
        end

        def status_scheduler
          "if [ -e #{fetch(:resque_pid_path)}/scheduler.pid ]; then \
             ps -p $(cat #{fetch(:resque_pid_path)}/scheduler.pid) | sed -n 2p \
           ;fi"
        end

        def start_scheduler(pid)
          "cd #{current_path} && RAILS_ENV=#{rails_env} \
           PIDFILE=#{pid} BACKGROUND=yes \
           #{"VERBOSE=1 " if fetch(:resque_verbose)}\
           MUTE=1 \
           nohup #{fetch(:bundle_cmd, "bundle")} exec rake \
           #{"environment " if fetch(:resque_environment_task)}\
           resque:scheduler #{output_redirection}"
        end

        def stop_scheduler(pid)
          "if [ -e #{pid} ]; then \
            #{maybe_sudo} kill -s #{resque_kill_signal} $(cat #{pid}) ; #{maybe_sudo} rm #{pid} \
           ;fi"
        end

        def create_pid_path
          "if [ ! -d #{fetch(:resque_pid_path)} ]; then \
            echo 'Creating #{fetch(:resque_pid_path)}' \
            && mkdir -p #{fetch(:resque_pid_path)}\
          ;fi"
        end

        namespace :resque do
          desc "See current worker status"
          task :status, :roles => lambda { workers_roles() }, :on_no_matching_servers => :continue do
            run(status_command)
          end

          desc "Start Resque workers"
          task :start, :roles => lambda { workers_roles() }, :on_no_matching_servers => :continue do
            run(create_pid_path)
            for_each_workers do |role, workers|
              worker_id = 1
              workers.each_pair do |queue, number_of_workers|
                logger.info "Starting #{number_of_workers} worker(s) with QUEUE: #{queue}"
                threads = []
                number_of_workers.times do
                  pid = "#{fetch(:resque_pid_path)}/resque_work_#{worker_id}.pid"
                  threads << Thread.new(pid) { |pid| run(start_command(queue, pid), :roles => role) }
                  worker_id += 1
                end
                threads.each(&:join)
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
          task :stop, :roles => lambda { workers_roles() }, :on_no_matching_servers => :continue do
            if run_and_rescue "[ -e #{fetch(:resque_pid_path)}/resque_work_1.pid ]"
              pids = capture("ls -1 #{fetch(:resque_pid_path)}/resque_work*.pid").lines.map(&:chomp)
              pids.each do |pid_file|
                pid = capture("cat #{pid_file}")
                if run_and_rescue "#{maybe_sudo} kill -0 #{pid}"
                  run("#{maybe_sudo} kill -s #{fetch(:resque_kill_signal)} #{pid} && #{maybe_sudo} rm #{pid_file}")
                else
                  puts "Process #{pid} from #{pid_file} is not running, cleaning up stale PID file"
                  run("#{maybe_sudo} rm #{pid_file}")
                end
              end
            else
              puts "No resque PID files found"
            end
          end

          desc "Restart running Resque workers"
          task :restart, :roles => lambda { workers_roles() }, :on_no_matching_servers => :continue do
            stop
            start
          end

          namespace :scheduler do
            desc "See current scheduler status"
            task :status, :roles => :resque_scheduler do
              run(status_scheduler)
            end

            desc "Starts resque scheduler with default configs"
            task :start, :roles => :resque_scheduler do
              run(create_pid_path)
              pid = "#{fetch(:resque_pid_path)}/scheduler.pid"
              run(start_scheduler(pid))
            end

            desc "Stops resque scheduler"
            task :stop, :roles => :resque_scheduler do
              pid = "#{fetch(:resque_pid_path)}/scheduler.pid"
              run(stop_scheduler(pid))
            end

            task :restart do
              stop
              start
            end
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  CapistranoResque::CapistranoIntegration.load_into(Capistrano::Configuration.instance)
end
