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


# WriteHandlers convert instances of Ruby types to their corresponding Transit
# semantic types, and ReadHandlers read convert transit values back into instances
# of Ruby types. transit-ruby ships with default sets of WriteHandlers for each
# of the Ruby types that map naturally to transit types, and ReadHandlers for each
# transit type. For the common case, the
# built-in handlers will suffice, but you can add your own extension types and/or
# override the built-in handlers.
#
# For example, Ruby has Date, Time, and DateTime, each with their
# own semantics. Transit has an instance type, which does not
# differentiate between Date and Time, so transit-ruby writes Dates,
# Times, and DateTimes as transit instances, and reads transit
# instances as DateTimes. If your application cares that Dates are
# different from DateTimes, you could register custom write and read
# handlers, overriding the built-in DateHandler and adding a new DateReadHandler.
#
# ```ruby
# class DateWriteHandler
#   def tag(_) "D" end
#   def rep(o) o.to_s end
#   def string_rep(o) o.to_s end
# end
#
# class DateReadHandler
#   def from_rep(rep)
#     Date.parse(rep)
#   end
# end
#
# io = StringIO.new('','w+')
# writer = Transit::Writer.new(:json, io, :handlers => {Date => DateWriteHandler.new})
# writer.write(Date.new(2014,7,22))
# io.string
# # => "[\"~#'\",\"~D2014-07-22\"]\n"
#
# reader = Transit::Reader.new(:json, StringIO.new(io.string), :handlers => {"D" => DateReadHandler.new})
# reader.read
# # => #<Date: 2014-07-22 ((2456861j,0s,0n),+0s,2299161j)>
# ```
module Transit
  ESC = "~"
  SUB = "^"
  RES = "`"
  TAG = "~#"
  MAP_AS_ARRAY = "^ "
  TIME_FORMAT  = "%FT%H:%M:%S.%LZ"
  QUOTE = "'"

  MAX_INT = 2**63 - 1
  MIN_INT = -2**63

  JSON_MAX_INT = 2**53 - 1
  JSON_MIN_INT = -JSON_MAX_INT
end

require 'set'
require 'time'
require 'uri'
require 'base64'
require 'bigdecimal'
require 'securerandom'
require 'forwardable'
require 'addressable/uri'
require 'transit/date_time_util'
require 'transit/transit_types'
require 'transit/rolling_cache'
require 'transit/write_handlers'
require 'transit/read_handlers'
require 'transit/marshaler/base'
require 'transit/writer'
require 'transit/decoder'
require 'transit/reader'

if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
  require 'lock_jar'
  LockJar.lock(File.join(File.dirname(__FILE__), "..", "Jarfile"))
  LockJar.load
  require 'transit/transit_service.jar'
  require 'jruby'
  com.cognitect.transit.ruby.TransitService.new.basicLoad(JRuby.runtime)
  require 'transit/marshaler/jruby/json'
  require 'transit/marshaler/jruby/messagepack'
else
  require 'transit/marshaler/cruby/json'
  require 'transit/marshaler/cruby/messagepack'
  require 'transit/unmarshaler/cruby/json'
  require 'transit/unmarshaler/cruby/messagepack'
end
