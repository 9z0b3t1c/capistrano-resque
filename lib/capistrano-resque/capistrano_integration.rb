require "capistrano"
require "capistrano/version"

module CapistranoResque
  class CapistranoIntegration
    def self.load_into(capistrano_config)
      capistrano_config.load do

        _cset(:num_of_queues, 1)
        _cset(:queue_name, "*")
        _cset(:app_env, (fetch(:rails_env) rescue "production"))
        _cset(:verbosity, 1)

        def remote_file_exists?(full_path)
          "true" ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
        end

        def remote_process_exists?(pid_file)
          capture("ps -p $(cat #{pid_file}) ; true").strip.split("\n").size == 2
        end

        def current_pids
          capture("ls #{current_path}/tmp/pids/resque_work*.pid").strip.split("\r\n")
        end

        namespace :resque do
          desc "See current worker status"
          task :status do
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
          task :start do
            puts "Starting #{num_of_queues} worker(s) with QUEUE: #{queue_name}"
            num_of_queues.times do |i|
              pid = "./tmp/pids/resque_worker_#{i}.pid"
              run "cd #{current_path} && RAILS_ENV=#{app_env} QUEUE=#{queue_name} \
PIDFILE=#{pid} BACKGROUND=yes LOGFILE=./log/resque-worker#{i}.log VVERBOSE=#{verbosity}  \
bundle exec rake environment resque:work"
            end
          end

          desc "Quit running Resque workers"
          task :stop do
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
          task :restart do
            stop
            start
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  CapistranoResque::CapistranoIntegration.load_into(Capistrano::Configuration.instance)
end
