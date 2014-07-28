# Copyright 2014 Cognitect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

unless File.exist?('../transit-format/examples/0.8/simple')
  puts <<-MSG
Before you can run the rspec examples, you need to install the
the https://github.com/cognitect/transit-format repo in a sibling
directory, e.g.

    cd ..
    git clone https://github.com/cognitect/transit-format

That repo contains exemplars used by transit-ruby's rspec examples
(in ../transit-format/examples/0.8/simple), so then you can:

    cd transit-ruby
    rspec

MSG
  exit
end

require 'json'
require 'rspec'
require 'wrong/adapters/rspec'
require 'transit'
require 'spec_helper-local' if File.exist?(File.expand_path('../spec_helper-local.rb', __FILE__))

RSpec.configure do |c|
  c.alias_example_to :fit, :focus => true
  c.filter_run_including :focus => true, :focused => true
  c.run_all_when_everything_filtered = true
  c.mock_with :nothing
end

ALPHA_NUM = 'abcdefghijklmnopqrstuvwxyzABCDESFHIJKLMNOPQRSTUVWXYZ_0123456789'

def random_alphanum
  ALPHA_NUM[rand(ALPHA_NUM.size)]
end

def random_string(max_length=10)
  l = rand(max_length) + 1
  (Array.new(l).map {|x| random_alphanum}).join
end

def random_strings(max_length=10, n=100)
  Array.new(n).map {random_string(max_length)}
end

def random_symbol(max_length=10)
  random_string(max_length).to_sym
end

def ints_centered_on(m, n=5)
  ((m-n)..(m+n)).to_a
end

def array_of_symbols(m, n=m)
  seeds = (0...m).map {|i| ("key%04d" % i).to_sym}
  seeds.cycle.take(n)
end

def hash_of_size(n)
  Hash[array_of_symbols(n).zip((0..n).to_a)]
end

Person = Struct.new("Person", :first_name, :last_name, :birthdate)

class PersonHandler
  def tag(_) "person"; end
  def rep(p) {:first_name => p.first_name, :last_name => p.last_name, :birthdate => p.birthdate} end
  def string_rep(p) nil end
end

def jruby?
  defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
end
