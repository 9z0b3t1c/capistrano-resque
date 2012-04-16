require 'capistrano'
require 'capistrano/version'

require "rubygems"; require "ruby-debug"; debugger
module CapistranoResque
  class CapistranoIntegration
    def self.load_into(capistrano_config)
      capistrano_config.load do
        namespace :resque do
          desc "test"
          task :test, :roles => :app, :except => {:no_release => true} do
              run "ls -lh"
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
