# -*- encoding: utf-8 -*-
require File.expand_path("../lib/capistrano-resque/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "capistrano-resque"
  gem.version     = CapistranoResque::VERSION.dup
  gem.author      = "Steven Shingler"
  gem.email       = "shingler@gmail.com"
  gem.homepage    = "https://github.com/sshingler/capistrano-resque"
  gem.summary     = %q{Resque integration for Capistrano}
  gem.description = %q{Capistrano plugin that integrates Resque server tasks.}

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "capistrano"
end