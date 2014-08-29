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

require 'msgpack'

module Transit
  module Unmarshaler
    # Transit::Reader::MessagePackUnmarshaler is responsible to read data on CRuby
    # @see https://github.com/cognitect/transit-format

    # @api private
    class MessagePack
      def initialize(io, opts)
        @decoder = Transit::Decoder.new(opts)
        @unpacker = ::MessagePack::Unpacker.new(io)
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
  end
end
