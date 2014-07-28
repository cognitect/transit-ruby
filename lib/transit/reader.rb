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
  # Transit::Reader converts incoming transit data into appropriate
  # values/objects in Ruby.
  # @see https://github.com/cognitect/transit-format
  class Reader
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

    # @param [Symbol] format required any of :msgpack, :json, :json_verbose
    # @param [IO]     io required
    # @param [Hash]   opts optional
    # Creates a new Reader configured to read from <tt>io</tt>,
    # expecting <tt>format</tt> (<tt>:json</tt>, <tt>:msgpack</tt>).
    #
    # Use opts to register custom read handlers, associating each one
    # with its tag.
    #
    # @example
    #
    #   json_reader                 = Transit::Reader.new(:json, io)
    #   # ^^ reads both :json and :json_verbose formats ^^
    #   msgpack_writer              = Transit::Reader.new(:msgpack, io)
    #   writer_with_custom_handlers = Transit::Reader.new(:json, io,
    #     :handlers => {"point" => PointReadHandler})
    #
    # @see Transit::ReadHandlers
    def initialize(format, io, opts={})
      @reader = case format
                when :json, :json_verbose
                  Unmarshaler::JsonUnmarshaler.new(io, opts)
                else
                  Unmarshaler::MessagePackUnmarshaler.new(io, opts)
                end
    end
  end
end
