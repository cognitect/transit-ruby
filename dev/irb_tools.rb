# Copyright (c) Cognitect, Inc.
# All rights reserved.

require 'stringio'

def time
  start = Time.now
  yield
  puts "Elapsed: #{Time.now - start}"
end

class Object
  def to_transit(format=:json)
    sio = StringIO.new
    Transit::Writer.new(format, sio).write(self)
    sio.string
  end
end

class String
  def from_transit(format=:json)
    sio = StringIO.new(self)
    Transit::Reader.new(format, sio).read
  end
end
