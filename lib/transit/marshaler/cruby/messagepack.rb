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
  module Marshaler
    class MessagePack < Transit::Marshaler::Base
      def default_opts
        {:prefer_strings => false,
          :max_int       => MAX_INT,
          :min_int       => MIN_INT}
      end

      def initialize(io, opts)
        @io = io
        @packer = ::MessagePack::Packer.new(io)
        super(default_opts.merge(opts))
      end

      def emit_array_start(size)
        @packer.write_array_header(size)
      end

      def emit_array_end
        # no-op
      end

      def emit_map_start(size)
        @packer.write_map_header(size)
      end

      def emit_map_end
        # no-op
      end

      def emit_value(obj, as_map_key=:ignore)
        @packer.write(obj)
      end

      def flush
        @packer.flush
        @io.flush
      end
    end
  end
end
