#!/usr/bin/env ruby

$LOAD_PATH << 'lib'
require 'transit'

r = Transit::Reader.new(:json)
w = Transit::Writer.new(STDOUT, :json)
r.read(STDIN) {|o| w.write o}
