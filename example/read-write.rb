#!/usr/bin/env ruby

$LOAD_PATH << 'lib'
require 'transit'

r = Transit::Reader.new(:json)
w = Transit::Writer.new(STDOUT, :json)
b = -> o {w.write o}
r.read(STDIN, &b)
