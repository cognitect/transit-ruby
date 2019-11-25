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
  # @see Transit::WriteHandlers
  module ReadHandlers
    class Default
      def from_rep(tag,val) TaggedValue.new(tag, val) end
    end
    class NilHandler
      def from_rep(_) nil end
    end
    class KeywordHandler
      def from_rep(v) v.to_sym end
    end
    class BooleanHandler
      def from_rep(v) v == "t" end
    end
    class ByteArrayHandler
      def from_rep(v) ByteArray.from_base64(v) end
    end
    class FloatHandler
      def from_rep(v) Float(v) end
    end
    class IntegerHandler
      def from_rep(v) v.to_i end
    end
    class BigIntegerHandler
      def from_rep(v) v.to_i end
    end
    class BigDecimalHandler
      def from_rep(v) BigDecimal(v) end
    end
    class SpecialNumbersHandler
      def from_rep(v)
        case v
        when "NaN"  then  Float::NAN
        when "INF"  then  Float::INFINITY
        when "-INF" then -Float::INFINITY
        else raise ArgumentError.new("Don't know how to handle #{v.inspect} for the \"z\" tag")
        end
      end
    end
    class IdentityHandler
      def from_rep(v) v end
    end
    class SymbolHandler
      def from_rep(v) Transit::Symbol.new(v) end
    end
    class TimeStringHandler
      def from_rep(v) DateTime.iso8601(v) end
    end
    class TimeIntHandler
      def from_rep(v) DateTimeUtil.from_millis(v.to_i) end
    end
    class UuidHandler
      def from_rep(v) UUID.new(v) end
    end
    class UriHandler
      def from_rep(v) Addressable::URI.parse(v) end
    end
    class SetHandler
      def from_rep(v) Set.new(v) end
    end
    class LinkHandler
      def from_rep(v) Link.new(v) end
    end
    class CmapHandler
      def from_rep(v) Hash[*v] end
    end
    class RatioHandler
      def from_rep(v) Rational(v[0], v[1]) end
    end

    DEFAULT_READ_HANDLERS = {
      "_" => NilHandler.new,
      ":" => KeywordHandler.new,
      "?" => BooleanHandler.new,
      "b" => ByteArrayHandler.new,
      "d" => FloatHandler.new,
      "i" => IntegerHandler.new,
      "n" => BigIntegerHandler.new,
      "f" => BigDecimalHandler.new,
      "c" => IdentityHandler.new,
      "$" => SymbolHandler.new,
      "t" => TimeStringHandler.new,
      "m" => TimeIntHandler.new,
      "u" => UuidHandler.new,
      "r" => UriHandler.new,
      "'" => IdentityHandler.new,
      "z" => SpecialNumbersHandler.new,
      "set"     => SetHandler.new,
      "link"    => LinkHandler.new,
      "list"    => IdentityHandler.new,
      "cmap"    => CmapHandler.new,
      "ratio"   => RatioHandler.new
    }.freeze

    DEFAULT_READ_HANDLER = Default.new

  end
end
