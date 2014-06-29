#!/usr/bin/env rake
require 'bundler'
require 'rspec/core/rake_task'

Bundler.setup

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :irb do
  sh 'irb -I lib -r transit -I dev -r irb_tools'
end

def project_name
  "transit-ruby"
end

def gemspec_filename
  @gemspec_filename = "#{project_name}.gemspec"
end

def build_version
  @build_version ||= begin
                       r = `build/revision`.chomp.to_i
                       "0.1.#{r}"
                     end
end

def gem_filename
  @gem_filename ||= "#{project_name}-#{build_version}.gem"
end

def gem_path
  @gem_path ||= "pkg/#{gem_filename}"
end

task :foo => [:ensure_committed]

desc "Build #{gem_filename}.gem into the pkg directory"
task :build do
  gemspec_content = File.read(gemspec_filename)
  File.open(gemspec_filename, 'w+') do |f|
    f.write gemspec_content.sub("0.0.0.dev", build_version)
  end
  sh "gem build #{gemspec_filename}"
  sh "mv #{gem_filename} #{gem_path}"
  File.open(gemspec_filename, 'w+') do |f|
    f.write gemspec_content
  end
end

desc "Build and install #{gem_filename}"
task :install => [:build] do
  sh "gem install #{gem_path}"
end

task :ensure_committed do
  raise "Can not release with uncommitted changes." unless `git status` =~ /clean/
end

desc "Create tag v#{build_version} and build and push #{gem_filename} to Rubygems"
task :release => [:ensure_committed, :build] do
  sh "git tag v#{build_version}"
  # gem push "#{target_path}"
end

desc "Uninstall #{project_name}"
task :uninstall do
  sh "gem uninstall #{project_name}"
end
