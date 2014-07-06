# Copyright (c) Cognitect, Inc.
# All rights reserved.

require 'ostruct'
require 'json'

Person = Struct.new(:first_name, :last_name, :birthdate)

people = [Person.new("Adinoran", "Barbosa", Date.parse("August 6, 1910")),
          Person.new("Beth", "Carvalho", Date.parse("May 5, 1946"))]

puts "People before: #{people.inspect}"
puts

###################################################
#### Writing

# Write handlers must define tag, rep, and string_rep methods. In this example,
# the rep is a map of attribute => value.
class PersonWriteHandler
  def tag(_) "person" end
  def rep(v) v.to_h end
  def string_rep(v) v.to_h.to_s end
end

write_io = StringIO.new('', 'w+')

writer = Transit::Writer.new(:json_verbose, # also try just :json to see encoding optimizations
                             write_io,
                             # Write handlers are registered in a map of types to their handlers
                             :handlers => {Person => PersonWriteHandler.new})
writer.write(people)

puts "Transit format: #{write_io.string}"
puts

###################################################
#### Reading

# Read handlers must define a from_rep method that converts the
# decoded Ruby object into what your application expects. In this
# example, transit decodes the transit value to a Ruby hash, which the
# PersonReadHandler then uses to build a Person.
class PersonReadHandler
  def from_rep(v)
    Person.new(v[:first_name],v[:last_name],v[:birthdate])
  end
end

read_io = StringIO.new(write_io.string)
reader = Transit::Reader.new(:json,
                             read_io,
                             # Read handlers are registered in a map of tags to their handlers.
                             :handlers => {"person" => PersonReadHandler.new})

reader.read {|v| puts "Resolved object: #{v.inspect}"}
