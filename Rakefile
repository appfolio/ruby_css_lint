# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "ruby_css_lint"
  gem.homepage = "http://github.com/amutz/ruby_css_lint"
  gem.license = "MIT"
  gem.summary = %Q{CSS Lint testing for Ruby}
  gem.description = %Q{Wraps up the CSS lint tool from https://github.com/stubbornella/csslint into a gem}
  gem.email = "andrew.mutz@appfolio.com"
  gem.authors = ["Andrew Mutz"]
  # dependencies defined in Gemfile
  
  Dir.glob('lib/**/*').each do |f|
    gem.files.include f
  end

  Dir.glob('csslint/**/*').each do |f|
    gem.files.include f
  end
  
  gem.files.include "js.jar"
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ruby_css_lint #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :css_lint do
  task :compile_rule_set do |t|
    csslint_working_directory = File.dirname(__FILE__) + "/csslint/"
    `cd #{csslint_working_directory}`
    `ant`
  end
end
