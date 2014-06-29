#!/usr/bin/env rake
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :irb do
  sh 'irb -I lib -r transit -I dev -r irb_tools'
end

Rake::Task["build"].clear
Rake::Task["install"].clear

task :build do
  r = `build/revision`.chomp.to_i
  @build_version = "0.0.#{r}"
  @target_filename = "transit-ruby-#{@build_version}.gem"
  @target_path     = "pkg/#{@target_filename}"
  gemspec = 'transit-ruby.gemspec'
  gemspec_content = File.read(gemspec)
  File.open(gemspec, 'w+') do |f|
    f.write gemspec_content.sub("0.0.0.dev", @build_version)
  end
  sh "gem build #{gemspec}"
  sh "mv #{@target_filename} #{@target_path}"
  File.open(gemspec, 'w+') do |f|
    f.write gemspec_content
  end
end

task :install => [:build] do
  sh "gem install #{@target_path}"
end

task :uninstall do
  sh "gem uninstall transit-ruby"
end
