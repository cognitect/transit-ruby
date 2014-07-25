# -*- ruby -*-

source 'https://rubygems.org'

if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
  gemspec :path => "jruby"
else
  gemspec :path => "cruby"
end

# Gemfile-custom is .gitignored, but eval'd here so you can add
# whatever dev tools you like to use to your local environment.
eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
