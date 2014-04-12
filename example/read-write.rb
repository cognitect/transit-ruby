#!/usr/bin/env ruby

$LOAD_PATH << 'lib'
require 'transit'

transport = ENV['TRANSPORT'] || "json"

r = Transit::Reader.new(transport.to_sym)
w = Transit::Writer.new(STDOUT, transport.to_sym)
r.read(STDIN) {|o| w.write o}
