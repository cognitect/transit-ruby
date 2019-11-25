# -*- ruby -*-
#!/usr/bin/env rake

require 'bundler'
Bundler.setup

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
Rake::Task[:spec].prerequisites << :compile
task :default => :spec

task :irb do
  sh 'irb -I lib -r transit -I dev -r irb_tools'
end

def project_name
  "transit-ruby"
end

def gemspec_filename
  @gemspec_filename ||= "#{project_name}.gemspec"
end

def spec_version
  @spec_version ||= /"(\d+\.\d+).dev"/.match(File.read(gemspec_filename))[1]
end

def jruby?
  defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
end

def jruby_version
  @jruby_version ||= `cat build/jruby_version`.chomp
end

def revision
  @revision ||= `build/revision`.chomp.to_i
end

def build_version
  @build_version ||= "#{spec_version}.#{revision}"
end

def published?
  gem_search = `gem q -rn "^transit-ruby$"`
  if jruby?
    gem_search =~ /\(#{revision}.*java.*\)/
  else
    gem_search =~ /\(#{revision}.*ruby.*\)/
  end
end

def tagged?
  `git tag` =~ /#{revision}/
end

def gem_filename
  if jruby?
    @gem_filename ||= "#{project_name}-#{build_version}-java.gem"
  else
    @gem_filename ||= "#{project_name}-#{build_version}.gem"
  end
end

def gem_path
  @gem_path ||= "pkg/#{gem_filename}"
end

desc "Use JRuby"
task :use_jruby do
  sh "rbenv local jruby-#{jruby_version}"
end

desc "Build #{gem_filename}.gem into the pkg directory"
task :build => [:compile] do
  begin
    gemspec_content = File.read(gemspec_filename)
    File.open(gemspec_filename, 'w+') do |f|
      f.write gemspec_content.sub("#{spec_version}.dev", build_version)
    end
    sh "gem build #{gemspec_filename}"
    sh "mkdir -p pkg"
    sh "mv #{gem_filename} #{gem_path}"
  ensure
    File.open(gemspec_filename, 'w+') do |f|
      f.write gemspec_content
    end
  end
end

desc "Build and install #{gem_filename}"
task :install => [:build] do
  sh "gem install #{gem_path}"
end

task :ensure_committed do
  raise "Cannot release with uncommitted changes." unless `git status` =~ /clean/
end

desc "Prepare to sign the gem"
task :prepare_to_sign do
  if jruby?
    puts "Gem signing is disabled for transit-ruby for JRuby"
  else
    private_key_path = File.expand_path(File.join(ENV['HOME'], '.gem', 'transit-ruby', 'gem-private_key.pem'))
    public_key_path  = File.expand_path(File.join(ENV['HOME'], '.gem', 'transit-ruby', 'gem-public_cert.pem'))
    if File.exist?(public_key_path) and File.exist?(private_key_path)
      ENV['SIGN_GEM'] = 'true'
    else
      raise "Missing one or both key files: #{public_key_path}, #{private_key_path}"
    end
  end
end

task :publish => [:build] do
  unless tagged?
    sh "git tag v#{build_version}"
  end
  if published?
    puts "Already published #{gem_filename}"
    exit
  end
  puts "Ready to publish #{gem_filename} to rubygems. Enter 'Y' to publish, anything else to stop:"
  input = STDIN.gets.chomp
  if input.downcase == 'y'
    sh "gem push #{gem_path}"
  else
    puts "Canceling publish (you entered #{input.inspect} instead of 'Y')"
    sh "git tag -d v#{build_version}"
  end
end

desc "Create tag v#{build_version} and build and push #{gem_filename} to Rubygems"
task :release => [:ensure_committed, :prepare_to_sign, :publish]

desc "Uninstall #{project_name}"
task :uninstall do
  sh "gem uninstall #{project_name}"
end

desc "Clean up generated files"
task :clobber do
  sh "rm -rf ./tmp ./pkg ./.yardoc doc lib/transit.jar"
end

# rake compiler
if jruby?
  require 'rake/javaextensiontask'
  Rake::JavaExtensionTask.new('transit') do |ext|
    require 'lock_jar'
    LockJar.lock
    locked_jars = LockJar.load(['default', 'development'])

    ext.name = 'transit'
    ext.ext_dir = 'ext'
    ext.lib_dir = 'lib'
    ext.source_version = '1.6'
    ext.target_version = '1.6'
    ext.classpath = locked_jars.map {|x| File.expand_path x}.join ':'
  end
else
  task :compile do
    # no-op for C Ruby
  end
end
