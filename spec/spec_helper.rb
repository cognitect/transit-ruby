require 'rspec'
require 'wrong/adapters/rspec'
require 'transit'
require 'spec_helper-local' if File.exist?(File.expand_path('../spec_helper-local.rb', __FILE__))

RSpec.configure do |c|
  c.alias_example_to :fit, :focus => true
  c.filter_run_including :focus => true, :focused => true
  c.run_all_when_everything_filtered = true
end

ALPHA_NUM = 'abcdefghijklmnopABCDESFHIJKLMNOP_0123456789'

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

Person = Struct.new("Person", :first_name, :last_name, :birthdate)

class PersonHandler
  def tag(_) "person"; end
  def rep(p) {:first_name => p.first_name, :last_name => p.last_name, :birthdate => p.birthdate} end
  def string_rep(p) nil end
end

class DateHandler
  def tag(_); "D"; end
  def rep(d) d.to_s end
  def string_rep(d) rep(d) end
end
