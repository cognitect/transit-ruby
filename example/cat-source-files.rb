# Copyright (c) Cognitect, Inc.
# All rights reserved.

#!/usr/bin/env ruby

sleep_secs = ENV['SLEEP']
max = ENV['MAX']

paths = max ? ARGV.take(max.to_i) : ARGV

paths.each do |path|
  sleep(sleep_secs.to_f) if sleep_secs
  print `cat #{path}`
end
