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
  # Transit::Writer marshals Ruby objects as transit values to an output stream.
  # @see https://github.com/cognitect/transit-format
  class Writer

    # @param [Symbol] format required :json, :json_verbose, or :msgpack
    # @param [IO]     io required
    # @param [Hash]   opts optional
    #
    # Creates a new Writer configured to write to <tt>io</tt> in
    # <tt>format</tt> (<tt>:json</tt>, <tt>:json_verbose</tt>,
    # <tt>:msgpack</tt>).
    #
    # Use opts to register custom write handlers, associating each one
    # with its type.
    #
    # @example
    #   json_writer                 = Transit::Writer.new(:json, io)
    #   json_verbose_writer         = Transit::Writer.new(:json_verbose, io)
    #   msgpack_writer              = Transit::Writer.new(:msgpack, io)
    #   writer_with_custom_handlers = Transit::Writer.new(:json, io,
    #     :handlers => {Point => PointWriteHandler})
    #
    # @see Transit::WriteHandlers
    def initialize(format, io, opts={})
      @marshaler = case format
                   when :json
                     Marshaler::Json.new(io,
                                         {:prefer_strings => true,
                                           :verbose        => false,
                                           :handlers       => {}}.merge(opts))
                   when :json_verbose
                     Marshaler::VerboseJson.new(io,
                                                {:prefer_strings => true,
                                                  :verbose        => true,
                                                  :handlers       => {}}.merge(opts))
                   else
                     Marshaler::MessagePack.new(io,
                                                {:prefer_strings => false,
                                                  :verbose        => false,
                                                  :handlers       => {}}.merge(opts))
                   end
    end

    # Converts a Ruby object to a transit value and writes it to this
    # Writer's output stream.
    #
    # @param obj the value to write
    # @example
    #   writer = Transit::Writer.new(:json, io)
    #   writer.write(Date.new(2014,7,22))
    def write(obj)
      @marshaler.marshal_top(obj)
    end
  end
end
