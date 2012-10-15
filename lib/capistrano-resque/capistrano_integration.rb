require "capistrano"
require "capistrano/version"

module CapistranoResque
  class CapistranoIntegration
    def self.load_into(capistrano_config)
      capistrano_config.load do

        _cset(:workers, {"*" => 1})
        _cset(:resque_kill_signal, "QUIT")

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

        namespace :resque do
          desc "See current worker status"
          task :status, :roles => lambda { workers_roles() }, :on_no_matching_servers => :continue do
            command = "if [ -e #{current_path}/tmp/pids/resque_work_1.pid ]; then \
                for f in $(ls #{current_path}/tmp/pids/resque_work*.pid); do ps -p $(cat $f) | sed -n 2p ;done \
               ;fi"
            run(command)
          end

          desc "Start Resque workers"
          task :start, :roles => lambda { workers_roles() }, :on_no_matching_servers => :continue do
            for_each_workers do |role, workers|
              worker_id = 1
              workers.each_pair do |queue, number_of_workers|
                puts "Starting #{number_of_workers} worker(s) with QUEUE: #{queue}"
                number_of_workers.times do
                  pid = "./tmp/pids/resque_work_#{worker_id}.pid"
                  run("cd #{current_path} && RAILS_ENV=#{rails_env} QUEUE=\"#{queue}\" \
                   PIDFILE=#{pid} BACKGROUND=yes VERBOSE=1 #{fetch(:bundle_cmd, "bundle")} exec rake environment resque:work >> #{shared_path}/log/resque.log 2>&1", 
                      :roles => role)
                  worker_id += 1
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
          task :stop, :roles => lambda { workers_roles() }, :on_no_matching_servers => :continue do
            command = "if [ -e #{current_path}/tmp/pids/resque_work_1.pid ]; then \
              for f in `ls #{current_path}/tmp/pids/resque_work*.pid`; do #{try_sudo} kill -s #{resque_kill_signal} `cat $f` ; rm $f ;done \
              ;fi"
            run(command)
          end

          desc "Restart running Resque workers"
          task :restart, :roles => lambda { workers_roles() }, :on_no_matching_servers => :continue do
            stop
            start
          end
          
          namespace :scheduler do
            desc "Starts resque scheduler with default configs"
            task :start, :roles => :resque_scheduler do
              run "cd #{current_path} && RAILS_ENV=#{rails_env} \
PIDFILE=./tmp/pids/scheduler.pid BACKGROUND=yes bundle exec rake resque:scheduler >> #{shared_path}/log/resque_scheduler.log 2>&1"
            end

            desc "Stops resque scheduler"
            task :stop, :roles => :resque_scheduler do
              pid = "#{current_path}/tmp/pids/scheduler.pid"
              command = "if [ -e #{pid} ]; then \
                #{try_sudo} kill $(cat #{pid}) ; rm #{pid} \
                ;fi"
              run(command)
              
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
