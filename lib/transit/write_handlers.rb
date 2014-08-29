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
  # WriteHandlers convert instances of Ruby types to their
  # corresponding Transit semantic types, and ReadHandlers read
  # convert transit values back into instances of Ruby
  # types. transit-ruby ships with default sets of WriteHandlers for
  # each of the Ruby types that map naturally to transit types, and
  # ReadHandlers for each transit type. For the common case, the
  # built-in handlers will suffice, but you can add your own extension
  # types and/or override the built-in handlers.
  #
  # ## Custom handlers
  #
  # For example, Ruby has Date, Time, and DateTime, each with their
  # own semantics. Transit has an instance type, which does not
  # differentiate between Date and Time, so transit-ruby writes Dates,
  # Times, and DateTimes as transit instances, and reads transit
  # instances as DateTimes. If your application cares that Dates are
  # different from DateTimes, you could register custom write and read
  # handlers, overriding the built-in DateHandler and adding a new
  # DateReadHandler.
  #
  # ### Write handlers
  #
  # Write handlers are required to expose <tt>tag</tt>, <tt>rep</tt>, and <tt>string_rep</tt> methods:
  #
  # ```ruby
  # class DateWriteHandler
  #   def tag(_) "D" end
  #   def rep(o) o.to_s end
  #   def string_rep(o) o.to_s end
  #   def verbose_handler(_) nil end # optional - see Verbose write handlers, below
  # end
  # ```
  #
  # <tt>tag</tt> returns the tag used to identify the transit type
  # (built-in or extension). It accepts the object being written,
  # which allows the handler to return different tags for different
  # semantics, e.g. the built-in IntHandler, which returns the tag "i"
  # for numbers that fit within a 64-bit signed integer and "n" for
  # anything outside that range.
  #
  # <tt>rep</tt> accepts the object being written and returns its wire
  # representation. This can be a scalar value (identified by a
  # one-character tag) or a map (Ruby Hash) or an array (identified by
  # a multi-character tag).
  #
  # <tt>string_rep</tt> accepts the object being written and returns a
  # string representation. Used when the object is a key in a map.
  #
  # ### Read handlers
  #
  # Read handlers are required to expose a single <tt>from_rep</tt> method:
  #
  # ```ruby
  # class DateReadHandler
  #   def from_rep(rep)
  #     Date.parse(rep)
  #   end
  # end
  # ```
  #
  # <tt>from_rep</tt> accepts the wire representation (without the tag), and
  # uses it to build an appropriate Ruby object.
  #
  # ### Usage
  #
  # ```ruby
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
  #
  # ## Custom types and representations
  #
  # Transit supports scalar and structured representations. The Date
  # example, above, demonstrates a String representation (scalar) of a
  # Date. This works well because it is a natural representation, but
  # it might not be a good solution for a more complex type, e.g. a
  # Point. While you _could_ represent a Point as a String, e.g.
  # <tt>("x:37,y:42")</tt>, it would be more efficient and arguably
  # more natural to represent it as an array of Integers:
  #
  # ```ruby
  # require 'ostruct'
  # Point = Struct.new(:x,:y) do
  #   def to_a; [x,y] end
  # end
  #
  # class PointWriteHandler
  #   def tag(_) "point" end
  #   def rep(o) o.to_a  end
  #   def string_rep(_) nil end
  # end
  #
  # class PointReadHandler
  #   def from_rep(rep)
  #     Point.new(*rep)
  #   end
  # end
  #
  # io = StringIO.new('','w+')
  # writer = Transit::Writer.new(:json_verbose, io, :handlers => {Point => PointWriteHandler.new})
  # writer.write(Point.new(37,42))
  # io.string
  # # => "{\"~#point\":[37,42]}\n"
  #
  # reader = Transit::Reader.new(:json, StringIO.new(io.string),
  #   :handlers => {"point" => PointReadHandler.new})
  # reader.read
  # # => #<struct Point x=37, y=42>
  # ```
  #
  # Note that Date used a one-character tag, "D", whereas Point uses a
  # multi-character tag, "point". Transit expects one-character tags
  # to have scalar representations (string, integer, float, boolean,
  # etc) and multi-character tags to have structural representations,
  # i.e. maps (Ruby Hashes) or arrays.
  #
  # ## Verbose write handlers
  #
  # Write handlers can, optionally, support the JSON-VERBOSE format by
  # providing a verbose write handler. Transit uses this for instances
  # (Ruby Dates, Times, DateTimes) to differentiate between the more
  # efficient format using an int representing milliseconds since 1970
  # in JSON mode from the more readable format using a String in
  # JSON-VERBOSE mode.
  #
  # ```ruby
  # inst = DateTime.new(1985,04,12,23,20,50,"0")
  #
  # io = StringIO.new('','w+')
  # writer = Transit::Writer.new(:json, io)
  # writer.write(inst)
  # io.string
  # #=> "[\"~#'\",\"~m482196050000\"]\n"
  #
  # io = StringIO.new('','w+')
  # writer = Transit::Writer.new(:json_verbose, io)
  # writer.write(inst)
  # io.string
  # #=> "{\"~#'\":\"~t1985-04-12T23:20:50.000Z\"}\n"
  # ```
  #
  # When you want a more human-readable format for your own custom
  # types in JSON-VERBOSE mode, create a second write handler and add
  # a <tt>verbose_handler</tt> method to the first handler that
  # returns an instance of the verbose handler:
  #
  # ```ruby
  # Element = Struct.new(:id, :name)
  #
  # class ElementWriteHandler
  #   def tag(_) "el" end
  #   def rep(v) v.id end
  #   def string_rep(v) v.name end
  #   def verbose_handler() ElementVerboseWriteHandler.new end
  # end
  #
  # class ElementVerboseWriteHandler < ElementWriteHandler
  #   def rep(v) v.name end
  # end
  #
  # write_handlers = {Element => ElementWriteHandler.new}
  #
  # e = Element.new(3, "Lithium")
  #
  # io = StringIO.new('','w+')
  # writer = Transit::Writer.new(:json, io, :handlers => write_handlers)
  # writer.write(e)
  # io.string
  # # => "[\"~#el\",3]\n"
  #
  # io = StringIO.new('','w+')
  # writer = Transit::Writer.new(:json_verbose, io, :handlers => write_handlers)
  # writer.write(e)
  # io.string
  # # => "{\"~#el\":\"Lithium\"}\n"
  # ```
  #
  # Note that you register the same handler collection; transit-ruby takes care of
  # asking for the verbose_handler for the :json_verbose format.
  module WriteHandlers
    class NilHandler
      def tag(_) "_" end
      def rep(_) nil end
      def string_rep(n) nil end
    end

    class KeywordHandler
      def tag(_) ":" end
      def rep(s) s.to_s end
      def string_rep(s) rep(s) end
    end

    class StringHandler
      def tag(_) "s" end
      def rep(s) s end
      def string_rep(s) s end
    end

    class TrueHandler
      def tag(_) "?" end
      def rep(_) true end
      def string_rep(_) "t" end
    end

    class FalseHandler
      def tag(_) "?" end
      def rep(_) false end
      def string_rep(_) "f" end
    end

    class IntHandler
      def tag(i) i > MAX_INT || i < MIN_INT ? "n" : "i" end
      def rep(i) i > MAX_INT || i < MIN_INT ? i.to_s : i end
      def string_rep(i) i.to_s end
    end

    class FloatHandler
      def tag(f)
        return "z" if f.nan?
        case f
        when Float::INFINITY, -Float::INFINITY
          "z"
        else
          "d"
        end
      end

      def rep(f)
        return "NaN" if f.nan?
        case f
        when  Float::INFINITY then "INF"
        when -Float::INFINITY then "-INF"
        else f
        end
      end

      def string_rep(f) rep(f).to_s end
    end

    class BigDecimalHandler
      def tag(_) "f" end
      def rep(f) f.to_s("f") end
      def string_rep(f) rep(f) end
    end

    class RationalHandler
      def tag(_) "ratio" end
      def rep(r) [r.numerator, r.denominator] end
      def string_rep(_) nil end
    end

    # TimeHandler, DateTimeHandler, and DateHandler all have different
    # implementations of string_rep. Here is the rationale:
    #
    # For all three, want to write out the same format
    # e.g. 2014-04-18T18:51:29.478Z, and we want the milliseconds to truncate
    # rather than round, eg 29.4786 seconds should be 29.478, not 29.479.
    # - "sss is the number of complete milliseconds since the start of the
    #    second as three decimal digits."
    # - http://www.ecma-international.org/ecma-262/5.1/#sec-15.9.1.15
    #
    # Some data points (see benchmarks/encoding_time.rb)
    # - Time and DateTime each offer iso8601 methods, but strftime is faster.
    # - DateTime's strftime (and iso8601) round millis
    # - Time's strftime (and iso8601) truncate millis
    # - we don't care about truncate v round for dates (which have 000 ms)
    # - date.to_datetime.strftime(...) is considerably faster than date.to_time.strftime(...)
    class TimeHandler
      def tag(_) "m" end
      def rep(t) DateTimeUtil.to_millis(t) end
      def string_rep(t) rep(t).to_s end
      def verbose_handler() VerboseTimeHandler.new end
    end

    class DateTimeHandler < TimeHandler
      def verbose_handler() VerboseDateTimeHandler.new end
    end

    class DateHandler     < TimeHandler
      def verbose_handler() VerboseDateHandler.new end
    end

    class VerboseTimeHandler
      def tag(_) "t" end
      def rep(t)
        # .getutc because we don't want to modify t
        t.getutc.strftime(Transit::TIME_FORMAT)
      end
      def string_rep(t) rep(t) end
    end

    class VerboseDateTimeHandler < VerboseTimeHandler
      def rep(t)
        # .utc because to_time already creates a new object
        t.to_time.utc.strftime(Transit::TIME_FORMAT)
      end
    end

    class VerboseDateHandler < VerboseTimeHandler
      def rep(d)
        # to_datetime because DateTime's strftime is faster
        # thank Time's, and millis are 000 so it doesn't matter
        # if we truncate or round.
        d.to_datetime.strftime(Transit::TIME_FORMAT)
      end
    end

    class UuidHandler
      def tag(_) "u" end
      def rep(u) [u.most_significant_bits, u.least_significant_bits] end
      def string_rep(u) u.to_s end
    end

    class LinkHandler
      def tag(_) "link" end
      def rep(l) l.to_h end
      def string_rep(_) nil end
    end

    class UriHandler
      def tag(_) "r" end
      def rep(u) u.to_s end
      def string_rep(u) rep(u) end
    end

    class AddressableUriHandler
      def tag(_) "r" end
      def rep(u) u.to_s end
      def string_rep(u) rep(u) end
    end

    class ByteArrayHandler
      def tag(_) "b" end
      def rep(b)
        if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
          b.value.to_java_bytes
        else
          b.to_base64
        end
      end
      def string_rep(b) rep(b) end
    end

    class TransitSymbolHandler
      def tag(_) "$" end
      def rep(s) s.to_s end
      def string_rep(s) rep(s) end
    end

    class ArrayHandler
      def tag(_) "array" end
      def rep(a) a end
      def string_rep(_) nil end
    end

    class MapHandler
      def handlers=(handlers)
        @handlers = handlers
      end

      def stringable_keys?(m)
        m.keys.all? {|k| (@handlers[k.class].tag(k).length == 1) }
      end

      def tag(m)
        stringable_keys?(m) ? "map" : "cmap"
      end

      def rep(m)
        stringable_keys?(m) ? m : m.reduce([]) {|a, kv| a.concat(kv)}
      end

      def string_rep(_) nil end
    end

    class SetHandler
      def tag(_) "set" end
      def rep(s) s.to_a end
      def string_rep(_) nil end
    end

    class TaggedValueHandler
      def tag(tv) tv.tag end
      def rep(tv) tv.rep end
      def string_rep(_) nil end
    end

    DEFAULT_WRITE_HANDLERS = {
      NilClass         => NilHandler.new,
      ::Symbol         => KeywordHandler.new,
      String           => StringHandler.new,
      TrueClass        => TrueHandler.new,
      FalseClass       => FalseHandler.new,
      Fixnum           => IntHandler.new,
      Bignum           => IntHandler.new,
      Float            => FloatHandler.new,
      BigDecimal       => BigDecimalHandler.new,
      Rational         => RationalHandler.new,
      Time             => TimeHandler.new,
      DateTime         => DateTimeHandler.new,
      Date             => DateHandler.new,
      UUID             => UuidHandler.new,
      Link             => LinkHandler.new,
      URI              => UriHandler.new,
      Addressable::URI => AddressableUriHandler.new,
      ByteArray        => ByteArrayHandler.new,
      Transit::Symbol  => TransitSymbolHandler.new,
      Array            => ArrayHandler.new,
      Hash             => MapHandler.new,
      Set              => SetHandler.new,
      TaggedValue      => TaggedValueHandler.new
    }.freeze
  end
end
