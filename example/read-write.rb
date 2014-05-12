# Copyright (c) Cognitect, Inc.
# All rights reserved.

#!/usr/bin/env ruby

$LOAD_PATH << 'lib'
require 'transit'

transport = ARGV[0] || "json"

r = Transit::Reader.new(transport.to_sym)
w = Transit::Writer.new(STDOUT, transport.to_sym)
r.read(STDIN) {|o| w.write o}
