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

require 'oj'

module Transit
  module Unmarshaler
    # Transit::Reader::MessagePackUnmarshaler is responsible to read data on CRuby
    # @see https://github.com/cognitect/transit-format

    # @api private
    class Json
      class ParseHandler
        def each(&block) @yield_v = block end
        def add_value(v) @yield_v[v] if @yield_v end

        def hash_start()      {} end
        def hash_set(h,k,v)   h.store(k,v) end
        def array_start()     [] end
        def array_append(a,v) a << v end

        def error(message, line, column)
          raise Exception.new(message, line, column)
        end
      end

      def initialize(io, opts)
        @io = io
        @decoder = Transit::Decoder.new(opts)
        @parse_handler = ParseHandler.new
      end

      # @see Reader#read
      def read
        if block_given?
          @parse_handler.each {|v| yield @decoder.decode(v)}
        else
          @parse_handler.each {|v| return @decoder.decode(v)}
        end
        Oj.sc_parse(@parse_handler, @io)
      end
    end
  end
end
