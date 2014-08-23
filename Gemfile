# -*- ruby -*-

source 'https://rubygems.org'

if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
  ruby '1.9.3', :engine => 'jruby', :engine_version => '1.7.13'
end

gemspec

# Gemfile-custom is .gitignored, but eval'd here so you can add
# whatever dev tools you like to use to your local environment.
eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
