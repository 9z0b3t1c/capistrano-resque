require "capistrano"
require "capistrano/version"

module CapistranoResque
  class CapistranoIntegration
    def self.load_into(capistrano_config)
      capistrano_config.load do

        _cset(:workers, {"*" => 1})
        _cset(:app_env, (fetch(:rails_env) rescue "production"))

        def remote_file_exists?(full_path)
          "true" ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
        end

        def remote_process_exists?(pid_file)
          capture("ps -p $(cat #{pid_file}) ; true").strip.split("\n").size == 2
        end

        def current_pids
          capture("ls #{current_path}/tmp/pids/resque_work*.pid 2>/dev/null || true").strip.split(/\r{0,1}\n/)
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
        

        namespace :resque do
          desc "See current worker status"
          task :status, :roles => :resque_worker do
            current_pids.each do |pid|
              if remote_file_exists?(pid)
                if remote_process_exists?(pid)
                  logger.important("Up and running", "Resque Worker: #{pid}")
                else
                  logger.important("Down", "Resque Worker: #{pid}")
                end
              end
            end
          end

          desc "Start Resque workers"
          task :start, :roles => workers_roles do
            worker_id = 1
            for_each_workers do |role, workers|
              workers.each_pair do |queue, number_of_workers|
                puts "Starting #{number_of_workers} worker(s) with QUEUE: #{queue}"
                number_of_workers.times do
                  pid = "./tmp/pids/resque_worker_#{worker_id}.pid"
                  run("cd #{current_path} && RAILS_ENV=#{app_env} QUEUE=\"#{queue}\" PIDFILE=#{pid} BACKGROUND=yes VERBOSE=1 bundle exec rake environment resque:work", 
                      :roles => role)
                  worker_id += 1
                end
              end
            end

          end

          desc "Quit running Resque workers"
          task :stop, :roles => workers_roles do
            current_pids.each do |pid|
              if remote_file_exists?(pid)
                if remote_process_exists?(pid)
                  logger.important("Stopping...", "Resque Worker: #{pid}")
                  run "#{try_sudo} kill `cat #{pid}`"
                else
                  run "rm #{pid}"
                  logger.important("Resque Worker #{pid} is not running.", "Resque")
                end
              else
                logger.important("No PIDs found. Check if Resque is running.", "Resque")
              end
            end
          end

          desc "Restart running Resque workers"
          task :restart, :roles => :resque_worker do
            stop
            start
          end

          namespace :scheduler do
            desc "Starts resque scheduler with default configs"
            task :start, :roles => :resque_scheduler do
              run "cd #{current_path} && RAILS_ENV=#{rails_env} \
PIDFILE=./tmp/pids/scheduler.pid BACKGROUND=yes bundle exec rake resque:scheduler"
            end

            desc "Stops resque scheduler"
            task :stop, :roles => :resque_scheduler do
              pid = "#{current_path}/tmp/pids/scheduler.pid"
              if remote_file_exists?(pid)
                logger.important("Shutting down resque scheduler...", "Resque Scheduler")
                run remote_process_exists?(pid) ? "#{try_sudo} kill `cat #{pid}`" : "rm #{pid}"
              else
                logger.important("Resque scheduler not running", "Resque Scheduler")
              end
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
