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
  module Marshaler
    class BaseJson
      include Transit::Marshaler::Base

      def initialize(io, opts)
        @oj = Oj::StreamWriter.new(io,opts.delete(:oj_opts) || {})
        @state = []
        @max_int = JSON_MAX_INT
        @min_int = JSON_MIN_INT
        @prefer_strings = true
        parse_options(opts)
      end

      def emit_array_start(size)
        @state << :array
        @oj.push_array
      end

      def emit_array_end
        @state.pop
        @oj.pop
      end

      def emit_map_start(size)
        @state << :map
        @oj.push_object
      end

      def emit_map_end
        @state.pop
        @oj.pop
      end

      def emit_int(tag, i, as_map_key, cache)
        if as_map_key || i > @max_int || i < @min_int
          emit_string(ESC, tag, i, as_map_key, cache)
        else
          emit_value(i, as_map_key)
        end
      end

      def emit_value(obj, as_map_key=false)
        if @state.last == :array
          @oj.push_value(obj)
        else
          as_map_key ? @oj.push_key(obj) : @oj.push_value(obj)
        end
      end

      def flush
        # no-op
      end
    end

    # @api private
    class Json < BaseJson
      def emit_map(m, cache)
        emit_array_start(-1)
        emit_value("^ ", false)
        m.each do |k,v|
          marshal(k, true, cache)
          marshal(v, false, cache)
        end
        emit_array_end
      end
    end

    # @api private
    class VerboseJson < BaseJson
      include Transit::Marshaler::VerboseHandlers

      def emit_string(prefix, tag, value, as_map_key, cache)
        emit_value("#{prefix}#{tag}#{value}", as_map_key)
      end

      def emit_tagged_value(tag, rep, cache)
        emit_map_start(1)
        emit_string(ESC, "#", tag, true, cache)
        marshal(rep, false, cache)
        emit_map_end
      end
    end
  end
end
