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

module Transit
  # Transit::Reader converts incoming transit data into appropriate values in Ruby.
  # @see https://github.com/cognitect/transit-format
  class Reader

    # @api private
    class JsonUnmarshaler
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

    # @api private
    class MessagePackUnmarshaler
      def initialize(io, opts)
        @decoder = Transit::Decoder.new(opts)
        @unpacker = MessagePack::Unpacker.new(io)
      end

      # @see Reader#read
      def read
        if block_given?
          @unpacker.each {|v| yield @decoder.decode(v)}
        else
          @decoder.decode(@unpacker.read)
        end
      end
    end

    extend Forwardable

    # @!method read
    #   Reads transit values from an IO (file, stream, etc), and
    #   converts each one to the appropriate Ruby object.
    #
    #   With a block, yields each object to the block as it is processed.
    #
    #   Without a block, returns a single object.
    #
    #   @example
    #     reader = Transit::Reader.new(:json, io)
    #     reader.read {|obj| do_something_with(obj)}
    #
    #     reader = Transit::Reader.new(:json, io)
    #     obj = reader.read
    def_delegators :@reader, :read

    # @param [Symbol] type required any of :msgpack, :json, :json_verbose
    # @param [IO]     io required
    # @param [Hash]   opts optional
    def initialize(type, io, opts={})
      @reader = case type
                when :json, :json_verbose
                  require 'oj'
                  JsonUnmarshaler.new(io, opts)
                else
                  require 'msgpack'
                  MessagePackUnmarshaler.new(io, opts)
                end
    end
  end
end
